// SPDX-License-Identifier: MIT
// NIFTSY protocol for NFT. Wrapper - main protocol contract
pragma solidity ^0.8.6;

import "./WrapperBase.sol";
import "./ERC165Checker.sol";
/**
 * @title ERC-721 Non-Fungible Token Wrapper 
 * @dev For wrpap existing ERC721 with ability add ERC20 collateral
 */
contract WrapperWithERC20Collateral is WrapperBase {
    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    struct ERC20Collateral {
        address erc20Token;
        uint256 amount;
    }

    uint16 public MAX_ERC20_COUNT = 25; //max coins type count in collateral  

    // Map from wrapped token id to array  with erc20 collateral balances
    mapping(uint256 => ERC20Collateral[]) public erc20Collateral;

    // Map from collateral conatrct address to bool(enabled-as-collateral) 
    //mapping(address => bool) public enabledForCollateral;

    event PartialUnWrapp(uint256 wrappedId, address owner);
    event SuspiciousFail(address failERC20, uint256 amount);
    event CollateralStatusChanged(address erc20, bool newStatus);
    event MaxCollateralCountChanged(uint256 oldValue, uint256 newValue);

    constructor (address _erc20) WrapperBase(_erc20) {
        partnersTokenList[_erc20].enabledForCollateral = true;
    } 

    /**
     * @dev Function for add arbitrary ERC20 collaterals 
     *
     * @param _wrappedTokenId  NFT id from thgis contarct
     * @param _erc20 address of erc20 collateral for add
     * @param _amount amount erc20 collateral for add  
     */
    function addERC20Collateral(
        uint256 _wrappedTokenId, 
        address _erc20, 
        uint256 _amount
    ) 
        external
        nonReentrant 
    {
        require(ownerOf(_wrappedTokenId) != address(0));
        require(enabledForCollateral(_erc20), "This ERC20 is not enabled for collateral");
        require(
            IERC20(_erc20).balanceOf(msg.sender) >= _amount,
            "Low balance for add collateral"
        );
        require(
            IERC20(_erc20).allowance(msg.sender, address(this)) >= _amount,
            "Please approve first"
        );
        
        ERC20Collateral[] storage e = erc20Collateral[_wrappedTokenId];
        //If collateral  with this _erc20 already exist just update
        if (getERC20CollateralBalance(_wrappedTokenId, _erc20) > 0) {
            for (uint256 i = 0; i < e.length; i ++) {
                if (e[i].erc20Token == _erc20) {
                    e[i].amount += _amount;
                    break;
                }
            }    

        } else {
            //So if we are here hence there is NO that _erc20 in collateral yet 
            //We can add more tokens if limit NOT exccedd
            require(e.length < MAX_ERC20_COUNT, "To much ERC20 tokens in collatteral");
            e.push(ERC20Collateral({
              erc20Token: _erc20, 
              amount: _amount
            }));

        }

        //Move collateral to contract balance
        IERC20(_erc20).safeTransferFrom(msg.sender, address(this), _amount); 
    }


    ////////////////////////////////////////////////
    ///// Admin Functions                       //// 
    ////////////////////////////////////////////////
    /**
     * @dev Function for operate Protocol ERC20 Collateral WhiteList 
     *
     * @param _erc20 - collateral token address
     * @param _isEnabled - collateral contract status for Protocol
     */
    function setCollateralStatus(address _erc20, bool _isEnabled) external onlyOwner {
        require(_erc20 != address(0), "No Zero Address");
        partnersTokenList[_erc20].enabledForCollateral = _isEnabled;
        emit CollateralStatusChanged(_erc20, _isEnabled);
    }

    /**
     * @dev Function set ERC20 Collateral Count Limit 
     *
     * @param _count - collateral count limit
     */
    function setMaxERC20CollateralCount(uint16 _count) external onlyOwner {
        MAX_ERC20_COUNT = _count;
        emit MaxCollateralCountChanged(MAX_ERC20_COUNT, _count);
    }
    ////////////////////////////////////////////////

    /**
     * @dev Function returns array with info about ERC20 
     * colleteral of wrapped token 
     *
     * @param _wrappedId  new protocol NFT id from this contarct
     */
    function getERC20Collateral(uint256 _wrappedId) external view returns (ERC20Collateral[] memory) {
        return erc20Collateral[_wrappedId];
    }

    /**
     * @dev Function returns collateral balance of this NFT in _erc20 
     * colleteral of wrapped token 
     *
     * @param _wrappedId  new protocol NFT id from this contarct
     * @param _erc20 - collateral token address
     */
    function getERC20CollateralBalance(uint256 _wrappedId, address _erc20) public returns (uint256) {
        ERC20Collateral[] memory e = erc20Collateral[_wrappedId];
        for (uint256 i = 0; i < e.length; i ++) {
            if (e[i].erc20Token == _erc20) {
                return e[i].amount;
            }
        }
    } 

    function enabledForCollateral(address _contract) public returns (bool) {
        return partnersTokenList[_contract].enabledForCollateral;
    }

    /**
     * @dev Helper function for check that _underlineContract supports 
     * some interface accordingly ERC165. So for check IERC721 support
     *  use _interfaceId like this:
     * /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     *_INTERFACE_ID_ERC721 = 0x80ac58cd;

     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     * bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
     *  
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     * bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63; 
     * ******************************
     * @param _underlineContract  contract address for check
     */
    function isERC721(address _underlineContract, bytes4 _interfaceId) public view returns (bool) {
        return _underlineContract.supportsInterface(_interfaceId);   
    }

    /////////////////////////////////////////////////////////////////////
    /////////////   Internals     ///////////////////////////////////////
    /////////////////////////////////////////////////////////////////////
    
    /**
     * @dev This hook may be overriden in inheritor contracts for extend
     * base functionality.
     *
     * @param _tokenId -wrapped token
     * 
     * must returna true for success unwrapping enable 
     */
    function _beforeUnWrapHook(uint256 _tokenId) internal virtual override(WrapperBase) returns (bool){
        return _returnERC20Collateral(_tokenId);
    }

    /**
     * @dev Function returns all ERC20 collateral to user who unWrap 
     * protocol token. Returns true if all tokens are transfered.
     * Otherwise returns false. In that case  need just call unWrap721
     * one more time
     * 
     *
     * @param _tokenId -wrapped token
     * 
     */
    function _returnERC20Collateral(uint256 _tokenId) internal returns (bool) {
        //First we need release erc20 collateral, because erc20 transfers are
        // can be expencive
        ERC20Collateral[] storage e = erc20Collateral[_tokenId];
        if (e.length > 0) { 
            for (uint256 i = e.length; i > 0; i --){
                // we need this try for protect from malicious 
                // erc20 contract that  can block unWrap NFT
                try 
                    // We dont use SafeTransfer because try works only for  external function call
                    // https://docs.soliditylang.org/en/v0.8.6/control-structures.html#try-catch
                    IERC20(e[i-1].erc20Token).transfer(msg.sender,  e[i-1].amount)
                {}
                catch {
                    emit SuspiciousFail(e[i-1].erc20Token, e[i-1].amount);
                }    
                e.pop();
                if (gasleft() <= 50000) {
                    emit PartialUnWrapp(_tokenId, msg.sender);
                    return false;
                }
            }

        }
        return true;

    }
}