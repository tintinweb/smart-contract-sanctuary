// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @creator: Pak
/// @author: manifold.xyz

////////////////////////////////////////////////////////////
//                                                        //
//                                                        //
//    $$$$$$\ $$\   $$\                                   //
//    \_$$  _|$$$\  $$ |                                  //
//      $$ |  $$$$\ $$ |                                  //
//      $$ |  $$ $$\$$ |                                  //
//      $$ |  $$ \$$$$ |                                  //
//      $$ |  $$ |\$$$ |                                  //
//    $$$$$$\ $$ | \$$ |                                  //
//    \______|\__|  \__|                                  //
//                                                        //
//                                                        //
//    $$$$$$$$\  $$$$$$\  $$\      $$\  $$$$$$\           //
//    $$  _____|$$  __$$\ $$$\    $$$ |$$  __$$\          //
//    $$ |      $$ /  $$ |$$$$\  $$$$ |$$ /  $$ |         //
//    $$$$$\    $$ |  $$ |$$\$$\$$ $$ |$$ |  $$ |         //
//    $$  __|   $$ |  $$ |$$ \$$$  $$ |$$ |  $$ |         //
//    $$ |      $$ |  $$ |$$ |\$  /$$ |$$ |  $$ |         //
//    $$ |       $$$$$$  |$$ | \_/ $$ | $$$$$$  |         //
//    \__|       \______/ \__|     \__| \______/          //
//                                                        //
//                                                        //
//    $$\      $$\ $$$$$$$$\                              //
//    $$ | $\  $$ |$$  _____|                             //
//    $$ |$$$\ $$ |$$ |                                   //
//    $$ $$ $$\$$ |$$$$$\                                 //
//    $$$$  _$$$$ |$$  __|                                //
//    $$$  / \$$$ |$$ |                                   //
//    $$  /   \$$ |$$$$$$$$\                              //
//    \__/     \__|\________|                             //
//                                                        //
//                                                        //
//    $$$$$$$$\ $$$$$$$\  $$\   $$\  $$$$$$\ $$$$$$$$\    //
//    \__$$  __|$$  __$$\ $$ |  $$ |$$  __$$\\__$$  __|   //
//       $$ |   $$ |  $$ |$$ |  $$ |$$ /  \__|  $$ |      //
//       $$ |   $$$$$$$  |$$ |  $$ |\$$$$$$\    $$ |      //
//       $$ |   $$  __$$< $$ |  $$ | \____$$\   $$ |      //
//       $$ |   $$ |  $$ |$$ |  $$ |$$\   $$ |  $$ |      //
//       $$ |   $$ |  $$ |\$$$$$$  |\$$$$$$  |  $$ |      //
//       \__|   \__|  \__| \______/  \______/   \__|      //
//                                                        //
//                                                        //
////////////////////////////////////////////////////////////

import "./AdminControl.sol";
import "./ReentrancyGuard.sol";
import "./IERC20.sol";
import "./ERC721.sol";
import "./Address.sol";
import "./EnumerableSet.sol";
import "./Strings.sol";

contract Fomoverse is ReentrancyGuard, AdminControl, ERC721 {

    using Address for address;
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 private _mintCount;
    uint256 public currentMintCount;
    uint256 public currentMintLimit;
    address public ashContract;
    uint256 public ashThreshold;

    string private _commonURI;
    string private _prefixURI;
    EnumerableSet.AddressSet private _approvedTokenReceivers;

    uint256 private _royaltyBps;
    address payable private _royaltyRecipient;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_CREATORCORE = 0xbb3bafd6;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_EIP2981 = 0x2a55205a;
    bytes4 private constant _INTERFACE_ID_ROYALTIES_RARIBLE = 0xb7799584;

    bool public active;

    constructor() ERC721("Fomoverse", "FOMO") {
        _mintCount = 1;
        _mint(msg.sender, _mintCount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, ERC721) returns (bool) {
        return ERC721.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId)
            || interfaceId == _INTERFACE_ID_ROYALTIES_CREATORCORE || interfaceId == _INTERFACE_ID_ROYALTIES_EIP2981
            || interfaceId == _INTERFACE_ID_ROYALTIES_RARIBLE;
    }

    function activate(uint256 limit, address ashContract_, uint256 ashThreshold_) external adminRequired {
        active = true;
        currentMintCount = 0;
        currentMintLimit = limit;
        ashContract = ashContract_;
        ashThreshold = ashThreshold_;
    }

    function deactivate() external adminRequired {
        active = false;
        currentMintCount = 0;
        currentMintLimit = 0;
    }

    function canMint() external view returns(bool) {
        return (active && currentMintCount < currentMintLimit && !msg.sender.isContract() && balanceOf(msg.sender) == 0 && IERC20(ashContract).balanceOf(msg.sender) >= ashThreshold);
    }

    function clear() external nonReentrant {
        require(active && currentMintCount < currentMintLimit, "Inactive");
        require(!msg.sender.isContract(), "Contracts cannot call mint");
        require(balanceOf(msg.sender) == 0, "Cannot mint more than one");

        // Private sale, check if individual has appropriate balance
        require(IERC20(ashContract).balanceOf(msg.sender) >= ashThreshold, "You do not have enough ASH to participate");

        _mintCount++;
        currentMintCount++;
        _mint(msg.sender, _mintCount);
    }

    /**
     * @dev Use a prefix commond uri for all tokens (<PREFIX><TOKEN_ID>).
     */
    function setPrefixURI(string calldata uri) external adminRequired {
        _prefixURI = uri;
        _commonURI = '';
    }

     /**
     * @dev Use a common uri for all tokens
     */
    function setCommonURI(string memory uri) external adminRequired {
        _commonURI = uri;
        _prefixURI = '';
    }

    function tokenURI(uint256 tokenId) public view override returns(string memory) {
        require(_exists(tokenId), "ERC721: URI query for nonexistent token");
        if (bytes(_commonURI).length > 0) {
          return _commonURI;
        }
        return string(abi.encodePacked(_prefixURI, tokenId.toString()));
    }


    /**
     * @dev Update royalties
     */
    function updateRoyalties(address payable recipient, uint256 bps) external adminRequired {
        _royaltyRecipient = recipient;
        _royaltyBps = bps;
    }

    /**
     * ROYALTY FUNCTIONS
     */
    function getRoyalties(uint256) external view returns (address payable[] memory recipients, uint256[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return (recipients, bps);
    }

    function getFeeRecipients(uint256) external view returns (address payable[] memory recipients) {
        if (_royaltyRecipient != address(0x0)) {
            recipients = new address payable[](1);
            recipients[0] = _royaltyRecipient;
        }
        return recipients;
    }

    function getFeeBps(uint256) external view returns (uint[] memory bps) {
        if (_royaltyRecipient != address(0x0)) {
            bps = new uint256[](1);
            bps[0] = _royaltyBps;
        }
        return bps;
    }

    function royaltyInfo(uint256, uint256 value) external view returns (address, uint256) {
        return (_royaltyRecipient, value*_royaltyBps/10000);
    }


    /**
     * Functions to add/remove approved contract based token receivers
     */
    function addTokenReceivers(address[] calldata addresses) external adminRequired {
        for (uint i = 0; i < addresses.length; i++) {
            _approvedTokenReceivers.add(addresses[i]);
        }
    }
    function removeTokenReceivers(address[] calldata addresses) external adminRequired {
        for (uint i = 0; i < addresses.length; i++) {
            _approvedTokenReceivers.remove(addresses[i]);
        }
    }
    function approvedTokenReceivers() external view returns(address[] memory addresses) {
        addresses = new address[](_approvedTokenReceivers.length());
        for (uint i = 0; i < _approvedTokenReceivers.length(); i++) {
            addresses[i] = _approvedTokenReceivers.at(i);
        }
    }
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        // Override transfer function to prevent transfers to unauthorized contracts
        if (to.isContract()) {
            require(_approvedTokenReceivers.contains(to), "Cannot transfer to contract");
        }
        super._transfer(from, to, tokenId);
    }
}