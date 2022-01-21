// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. Wrapper - main protocol contract
pragma solidity 0.8.11;

import "WrapperBaseV1.sol";

contract WrapperForRent is WrapperBaseV1 {
    

    // mapping from wNFT to wNFT Holder(tenant).
    // we need this map because there is no single owner in ERC1155
    // and for unwrap we need know who  hold  wNFT 
    mapping(address => mapping(uint256 => address)) public rentersOf;

    constructor(address _erc20) WrapperBaseV1(_erc20){

    }

    function wrap(ETypes.INData calldata _inData, ETypes.AssetItem[] calldata _collateral, address _wrappFor) 
        public 
        override
        payable 
        returns (ETypes.AssetItem memory) 
    {
        ETypes.AssetItem memory wNFT_= super.wrap(_inData, _collateral, _wrappFor);
        rentersOf[wNFT_.asset.contractAddress][wNFT_.tokenId] = _wrappFor;  
        return wNFT_;

    }

    function _checkCoreUnwrap(ETypes.AssetType _wNFTType, address _wNFTAddress, uint256 _wNFTTokenId) 
        internal 
        view 
        override 
        returns (address burnFor, uint256 burnBalance) 
    {
        if (_wNFTType == ETypes.AssetType.ERC721) {
            // Only token owner or unwraper can UnWrap
            burnFor = IERC721Mintable(_wNFTAddress).ownerOf(_wNFTTokenId);
            require(getWrappedToken(_wNFTAddress, _wNFTTokenId).unWrapDestinition == msg.sender,
                'Only unWrapDestinition can unwrap it'
            ); 
            return (burnFor, burnBalance);

        } else if (_wNFTType == ETypes.AssetType.ERC1155) {
            burnBalance = IERC1155Mintable(_wNFTAddress).totalSupply(_wNFTTokenId);
            burnFor = rentersOf[_wNFTAddress][_wNFTTokenId];
            require(
                burnBalance ==
                IERC1155Mintable(_wNFTAddress).balanceOf(burnFor, _wNFTTokenId)
                ,'ERC115 unwrap available only for all totalSupply'
            );
            // Only token owner or unwraper can UnWrap
            if (getWrappedToken(_wNFTAddress, _wNFTTokenId).unWrapDestinition != msg.sender) {
                require(
                   !_checkRule(0x0001, getWrappedToken(_wNFTAddress, _wNFTTokenId).rules), 
                   'Only unWrapDestinition can unwrap forbidden wnft'
                );
                require(msg.sender == burnFor,
                   'Only unWrapDestinition or owner can unwrap this wnft'
                );
            }

            return (burnFor, burnBalance);
            
        } else {
            revert UnSupportedAsset(ETypes.AssetItem(ETypes.Asset(_wNFTType,_wNFTAddress),_wNFTTokenId, 0));
        }
    }

}

// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. Wrapper - main protocol contract
pragma solidity 0.8.11;

import "Ownable.sol";
import "ERC721Holder.sol";
import "ERC1155Holder.sol";
import "ReentrancyGuard.sol";
import "IFeeRoyaltyModel.sol";
import "IWrapper.sol";
import "IAdvancedWhiteList.sol";
import "TokenService.sol";

// #### Envelop ProtocolV1 Rules
// 15   14   13   12   11   10   9   8   7   6   5   4   3   2   1   0  <= Bit number(dec)
// ------------------------------------------------------------------------------------  
//  1    1    1    1    1    1   1   1   1   1   1   1   1   1   1   1
//  |    |    |    |    |    |   |   |   |   |   |   |   |   |   |   |
//  |    |    |    |    |    |   |   |   |   |   |   |   |   |   |   +-No_Unwrap
//  |    |    |    |    |    |   |   |   |   |   |   |   |   |   +-No_Wrap 
//  |    |    |    |    |    |   |   |   |   |   |   |   |   +-No_Transfer
//  |    |    |    |    |    |   |   |   |   |   |   |   +-No_Collateral
//  |    |    |    |    |    |   |   |   |   |   |   +-reserved_core
//  |    |    |    |    |    |   |   |   |   |   +-reserved_core
//  |    |    |    |    |    |   |   |   |   +-reserved_core  
//  |    |    |    |    |    |   |   |   +-reserved_core
//  |    |    |    |    |    |   |   |
//  |    |    |    |    |    |   |   |
//  +----+----+----+----+----+---+---+
//      for use in extendings
/**
 * @title Non-Fungible Token Wrapper
 * @dev Make  wraping for existing ERC721 & ERC1155 and empty 
 */
contract WrapperBaseV1 is ReentrancyGuard, ERC721Holder, ERC1155Holder, IWrapper, TokenService, Ownable {
    //using SafeERC20 for IERC20Extended;


    uint256 public MAX_COLLATERAL_SLOTS = 260;
    address public protocolTechToken;
    address public protocolWhiteList;
    //address public tokenService;

     
    mapping(address => bool) public trustedOperators;

    // Map from wrapping asset type to wnft contract address and last minted id
    mapping(ETypes.AssetType => ETypes.NFTItem) public lastWNFTId;  
    
    // Map from wrapped token address and id => wNFT record 
    mapping(address => mapping(uint256 => ETypes.WNFT)) internal wrappedTokens; //? Private in Production

    //error UnSupportedAsset(ETypes.AssetItem asset);


    modifier onlyTrusted() {
        require (trustedOperators[msg.sender] == true, "Only trusted address");
        _;
    }

    constructor(address _erc20) {
        require(_erc20 != address(0), "ProtocolTechToken cant be zero value");
        protocolTechToken = _erc20;
        trustedOperators[msg.sender] = true;
        IFeeRoyaltyModel(protocolTechToken).registerModel(); 
    }

    
    function wrap(ETypes.INData calldata _inData, ETypes.AssetItem[] calldata _collateral, address _wrappFor) 
        public 
        virtual
        payable 
        nonReentrant 
        returns (ETypes.AssetItem memory) 
    {

        // 0. Check assetIn asset
        require(_checkWrap(_inData,_wrappFor),
            "Wrap check fail"
        );
        // 1. Take users inAsset
        if ( _inData.inAsset.asset.assetType != ETypes.AssetType.NATIVE &&
             _inData.inAsset.asset.assetType != ETypes.AssetType.EMPTY
        ) 
        {
            require(
                _mustTransfered(_inData.inAsset) == _transferSafe(_inData.inAsset, msg.sender, address(this)),
                "Suspicious asset for wrap"
            );
        }
        
        // 2. Mint wNFT
        _mintNFT(
            _inData.outType,     // what will be minted instead of wrapping asset
            lastWNFTId[_inData.outType].contractAddress, // wNFT contract address
            _wrappFor,                                   // wNFT receiver (1st owner) 
            lastWNFTId[_inData.outType].tokenId + 1,        
            _inData.outBalance                           // wNFT tokenId
        );
        lastWNFTId[_inData.outType].tokenId += 1;  //Save just minted id 

        
        // 4. Safe wNFT info
        _saveWNFTinfo(
            lastWNFTId[_inData.outType].contractAddress, 
            lastWNFTId[_inData.outType].tokenId,
            _inData
        );

        if (_checkAddCollateral(
                lastWNFTId[_inData.outType].contractAddress, 
                lastWNFTId[_inData.outType].tokenId,
                _collateral
            )) 
        {

            _addCollateral(
                lastWNFTId[_inData.outType].contractAddress, 
                lastWNFTId[_inData.outType].tokenId, 
                _collateral
            );

        } 
         
        // Charge Fee Hook 
        // There is No Any Fees in Protocol
        // So this hook can be used in b2b extensions of Envelop Protocol 
        // 0x02 - feeType for WrapFee
        _chargeFees(
            lastWNFTId[_inData.outType].contractAddress, 
            lastWNFTId[_inData.outType].tokenId, 
            msg.sender, 
            address(this), 
            0x02
        );
        

        emit WrappedV1(
            _inData.inAsset.asset.contractAddress,        // inAssetAddress
            lastWNFTId[_inData.outType].contractAddress,  // outAssetAddress
            _inData.inAsset.tokenId,                      // inAssetTokenId 
            lastWNFTId[_inData.outType].tokenId,          // outTokenId 
            _wrappFor,                                    // wnftFirstOwner
            msg.value,                                    // nativeCollateralAmount
            _inData.rules                                 // rules
        );
        return ETypes.AssetItem(
            ETypes.Asset(_inData.outType, lastWNFTId[_inData.outType].contractAddress),
            lastWNFTId[_inData.outType].tokenId,
            _inData.outBalance
        );
    }

    function wrapUnsafe(ETypes.INData calldata _inData, ETypes.AssetItem[] calldata _collateral, address _wrappFor) 
        public 
        virtual
        payable
        onlyTrusted 
        nonReentrant 
        returns (ETypes.AssetItem memory) 
    {
        // 1. Take users inAsset
        if ( _inData.inAsset.asset.assetType != ETypes.AssetType.NATIVE &&
             _inData.inAsset.asset.assetType != ETypes.AssetType.EMPTY
            )
        { 
            _transfer(_inData.inAsset, msg.sender, address(this));
        }
        // 2. Mint wNFT
        _mintNFT(
            _inData.outType,     // what will be minted instead of wrapping asset
            lastWNFTId[_inData.outType].contractAddress, // wNFT contract address
            _wrappFor,                                   // wNFT receiver (1st owner) 
            lastWNFTId[_inData.outType].tokenId + 1,        
            _inData.outBalance                           // wNFT tokenId
        );
        lastWNFTId[_inData.outType].tokenId += 1;  //Save just minted id 


        // 4. Safe wNFT info
        _saveWNFTinfo(
            lastWNFTId[_inData.outType].contractAddress, 
            lastWNFTId[_inData.outType].tokenId,
            _inData
        );

        _addCollateral(
            lastWNFTId[_inData.outType].contractAddress, 
            lastWNFTId[_inData.outType].tokenId, 
            _collateral
        );

        emit WrappedV1(
            _inData.inAsset.asset.contractAddress,        // inAssetAddress
            lastWNFTId[_inData.outType].contractAddress,  // outAssetAddress
            _inData.inAsset.tokenId,                      // inAssetTokenId 
            lastWNFTId[_inData.outType].tokenId,          // outTokenId 
            _wrappFor,                                    // wnftFirstOwner
            msg.value,                                    // nativeCollateralAmount
            _inData.rules                                 // rules
        );
        return ETypes.AssetItem(
            ETypes.Asset(_inData.outType, lastWNFTId[_inData.outType].contractAddress),
            lastWNFTId[_inData.outType].tokenId,
            _inData.outBalance
        );
    }


    function addCollateral(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        ETypes.AssetItem[] calldata _collateral
    ) external payable virtual {

        require(
            _checkAddCollateral(
                _wNFTAddress, 
                _wNFTTokenId,
                _collateral
            ),
            "Forbidden add collateral"
        );
        _addCollateral(
            _wNFTAddress, 
            _wNFTTokenId, 
            _collateral
        );
    }

    function addCollateralUnsafe(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        ETypes.AssetItem[] calldata _collateral
    ) 
        external 
        payable 
        virtual 
        onlyTrusted 
    {

        _addCollateral(
            _wNFTAddress, 
            _wNFTTokenId, 
            _collateral
        );
    }

    function unWrap(ETypes.AssetType _wNFTType, address _wNFTAddress, uint256 _wNFTTokenId) external virtual {
        unWrap(_wNFTType,_wNFTAddress, _wNFTTokenId, false);
    }

    function unWrap(ETypes.AssetType _wNFTType, address _wNFTAddress, uint256 _wNFTTokenId, bool _isEmergency) public virtual {
        // 0. Check core protocol logic:
        // - who and what possible to unwrap
        (address burnFor, uint256 burnBalance) = _checkCoreUnwrap(_wNFTType, _wNFTAddress, _wNFTTokenId);
        
        
        // // 1. Check  rules, such as unWrapless
        // require(
        //     _checkUnwrap(_wNFTAddress, _wNFTTokenId),
        //     "UnWrap check fail"

        // );

        // 2. Check  locks = move to _checkUnwrap
        require(
            _checkLocks(_wNFTAddress, _wNFTTokenId)
        );

        // 3. Charge Fee Hook 
        // There is No Any Fees in Protocol
        // So this hook can be used in b2b extensions of Envelop Protocol 
        // 0x03 - feeType for UnWrapFee
        // 
        _chargeFees(_wNFTAddress, _wNFTTokenId, msg.sender, address(this), 0x03);
        (uint256 nativeCollateralAmount, ) = getCollateralBalanceAndIndex(
            _wNFTAddress, 
            _wNFTTokenId,
            ETypes.AssetType.NATIVE,
            address(0),
            0
        );
        ///////////////////////////////////////////////
        ///  Place for hook                        ////
        ///////////////////////////////////////////////
        // 4. Safe return collateral to appropriate benificiary

        if (!_beforeUnWrapHook(_wNFTAddress, _wNFTTokenId, _isEmergency)) {
            return;
        }
        
        // 5. BurnWNFT
        _burnNFT(
            _wNFTType, 
            _wNFTAddress, 
            burnFor,  // msg.sender, 
            _wNFTTokenId, 
            burnBalance
        );
        
        // 5. Return Original
        if (wrappedTokens[_wNFTAddress][_wNFTTokenId].inAsset.asset.assetType != ETypes.AssetType.NATIVE && 
            wrappedTokens[_wNFTAddress][_wNFTTokenId].inAsset.asset.assetType != ETypes.AssetType.EMPTY
        ) 
        {

            if (!_isEmergency){
                _transferSafe(
                    wrappedTokens[_wNFTAddress][_wNFTTokenId].inAsset,
                    address(this),
                    wrappedTokens[_wNFTAddress][_wNFTTokenId].unWrapDestinition
                );
            } else {
                _transferEmergency (
                    wrappedTokens[_wNFTAddress][_wNFTTokenId].inAsset,
                    address(this),
                    wrappedTokens[_wNFTAddress][_wNFTTokenId].unWrapDestinition
                );
            }
        }        
        emit UnWrappedV1(
            _wNFTAddress,
            wrappedTokens[_wNFTAddress][_wNFTTokenId].inAsset.asset.contractAddress,
            _wNFTTokenId, 
            wrappedTokens[_wNFTAddress][_wNFTTokenId].inAsset.tokenId,
            wrappedTokens[_wNFTAddress][_wNFTTokenId].unWrapDestinition, 
            nativeCollateralAmount,  // TODO Check  GAS
            wrappedTokens[_wNFTAddress][_wNFTTokenId].rules 
        );
    } 

    function chargeFees(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        address _from, 
        address _to,
        bytes1 _feeType
    ) 
        public
        virtual  
        returns (bool) 
    {
        //TODO  only wNFT contract can  execute  this(=charge fee)
        require(msg.sender == _wNFTAddress || msg.sender == address(this), 
            "Only for wNFT or wrapper"
        );
        require( _chargeFees(_wNFTAddress, _wNFTTokenId, _from, _to, _feeType),
            "Fee charge fail"
        );
    }
    /////////////////////////////////////////////////////////////////////
    //                    Admin functions                              //
    /////////////////////////////////////////////////////////////////////
    function setWNFTId(
        ETypes.AssetType  _assetOutType, 
        address _wnftContract, 
        uint256 _tokenId
    ) external onlyOwner {
        require(_wnftContract != address(0), "No zero address");
        lastWNFTId[_assetOutType] = ETypes.NFTItem(_wnftContract, _tokenId);
    }

    function setWhiteList(address _wlAddress) external onlyOwner {
        protocolWhiteList = _wlAddress;
    }

    // function setTokenService(address _serviveAddress) external onlyOwner {
    //     tokenService = _serviveAddress;
    // }

    function setTrustedAddres(address _operator, bool _status) public onlyOwner {
        trustedOperators[_operator] = _status;
    }

    /////////////////////////////////////////////////////////////////////


    function getWrappedToken(address _wNFTAddress, uint256 _wNFTTokenId) public view returns (ETypes.WNFT memory) {
        return wrappedTokens[_wNFTAddress][_wNFTTokenId];

    }

    function getOriginalURI(address _wNFTAddress, uint256 _wNFTTokenId) public view returns(string memory) {
        ETypes.AssetItem memory _wnftInAsset = getWrappedToken(
                _wNFTAddress, _wNFTTokenId
        ).inAsset;

        if (_wnftInAsset.asset.assetType == ETypes.AssetType.ERC721) {
            return IERC721Metadata(_wnftInAsset.asset.contractAddress).tokenURI(_wnftInAsset.tokenId);
        
        } else if (_wnftInAsset.asset.assetType == ETypes.AssetType.ERC1155) {
            return IERC1155MetadataURI(_wnftInAsset.asset.contractAddress).uri(_wnftInAsset.tokenId);
        
        } else {
            return '';
        } 
    }

    function getCollateralBalanceAndIndex(
        address _wNFTAddress, 
        uint256 _wNFTTokenId,
        ETypes.AssetType _collateralType, 
        address _erc,
        uint256 _tokenId
    ) public view returns (uint256, uint256) 
    {
        //ERC20Collateral[] memory e = erc20Collateral[_wrappedId];
        for (uint256 i = 0; i < wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral.length; i ++) {
            if (wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[i].asset.contractAddress == _erc &&
                wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[i].tokenId == _tokenId &&
                wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[i].asset.assetType == _collateralType 
            ) 
            {
                return (wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[i].amount, i);
            }
        }
    } 
    /////////////////////////////////////////////////////////////////////
    //                    Internals                                    //
    /////////////////////////////////////////////////////////////////////
    function _saveWNFTinfo(
        address wNFTAddress, 
        uint256 tokenId, 
        ETypes.INData calldata _inData
        //ETypes.AssetItem[] calldata _collateral
    ) internal virtual 
    {
        wrappedTokens[wNFTAddress][tokenId].inAsset = _inData.inAsset;
        // TODO Check unwrap distinition
        wrappedTokens[wNFTAddress][tokenId].unWrapDestinition = _inData.unWrapDestinition;
        wrappedTokens[wNFTAddress][tokenId].rules = _inData.rules;
        
        // Copying of type struct ETypes.Fee memory[] memory to storage not yet supported.
        for (uint256 i = 0; i < _inData.fees.length; i ++) {
            wrappedTokens[wNFTAddress][tokenId].fees.push(_inData.fees[i]);            
        }

        for (uint256 i = 0; i < _inData.locks.length; i ++) {
            wrappedTokens[wNFTAddress][tokenId].locks.push(_inData.locks[i]);            
        }

        for (uint256 i = 0; i < _inData.royalties.length; i ++) {
            wrappedTokens[wNFTAddress][tokenId].royalties.push(_inData.royalties[i]);            
        }

    }

    function _addCollateral(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        ETypes.AssetItem[] calldata _collateral
    ) internal virtual 
    {
        
        // Process Native Colleteral
        if (msg.value > 0) {
            _updateCollateralInfo(
                _wNFTAddress, 
                _wNFTTokenId,
                ETypes.AssetItem(
                    ETypes.Asset(ETypes.AssetType.NATIVE, address(0)),
                    0,
                    msg.value
                )
            );
            emit CollateralAdded(
                    _wNFTAddress, 
                    _wNFTTokenId, 
                    uint8(ETypes.AssetType.NATIVE),
                    address(0),
                    0,
                    msg.value
                );
        }
       
        // Process Token Colleteral
        for (uint256 i = 0; i <_collateral.length; i ++) {
            if (_collateral[i].asset.assetType != ETypes.AssetType.NATIVE) {
                require(
                    _mustTransfered(_collateral[i]) == _transferSafe(_collateral[i], msg.sender, address(this)),
                    "Suspicious asset for wrap"
                );
                _updateCollateralInfo(
                    _wNFTAddress, 
                    _wNFTTokenId,
                    _collateral[i]
                );
                emit CollateralAdded(
                    _wNFTAddress, 
                    _wNFTTokenId, 
                    uint8(_collateral[i].asset.assetType),
                    _collateral[i].asset.contractAddress,
                    _collateral[i].tokenId,
                    _collateral[i].amount
                );
            }
        }
    }

    function _updateCollateralInfo(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        ETypes.AssetItem memory collateralItem
    ) internal virtual 
    {
        if (wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral.length == 0) {
            // Just add first record in empty collateral storage
            wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral.push(collateralItem);
        } else {
            // Collateral storage is not empty
            (uint256 _amnt, uint256 _index) = getCollateralBalanceAndIndex(
                _wNFTAddress, 
                _wNFTTokenId,
                collateralItem.asset.assetType, 
                //ETypes.AssetType.ERC20,
                collateralItem.asset.contractAddress,
                collateralItem.tokenId
            );
            /////////////////////////////////////////
            //  ERC20 & NATIVE Collateral         ///
            /////////////////////////////////////////
            if (collateralItem.asset.assetType == ETypes.AssetType.ERC20 ||
                 collateralItem.asset.assetType == ETypes.AssetType.NATIVE){

                if (_amnt > 0) {
                    wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[_index].amount += collateralItem.amount;
                } else {
                //So if we are here hence there is NO that _erc20 in collateral yet 
                //We can add more tokens if limit NOT exccedd
                    require(
                        wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral.length < MAX_COLLATERAL_SLOTS, 
                        "To much tokens in collatteral"
                    );
                    wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral.push(collateralItem);
                }
                return;    
            }

            /////////////////////////////////////////
            //  ERC1155 Collateral                ///
            /////////////////////////////////////////
            if (collateralItem.asset.assetType == ETypes.AssetType.ERC1155) {
                if (_amnt> 0) {
                    wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[_index].amount += collateralItem.amount;
                } else {
                    //So if we are here hence there is NO that _erc20 in collateral yet 
                    //We can add more tokens if limit NOT exccedd
                    require(
                        wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral.length < MAX_COLLATERAL_SLOTS, 
                        "To much tokens in collatteral"
                    );
                    wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral.push(collateralItem);
                }
                return;
            }    

            /////////////////////////////////////////
            //  ERC721 Collateral                 ///
            /////////////////////////////////////////
            if (collateralItem.asset.assetType == ETypes.AssetType.ERC721 ) {
                require(
                    wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral.length < MAX_COLLATERAL_SLOTS, 
                    "To much  tokens in collatteral"
                );
                wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral.push(collateralItem);
                return;
            }
        }
    }


    function _chargeFees(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        address _from, 
        address _to,
        bytes1 _feeType
    ) 
        internal
        virtual  
        returns (bool) 
    {
        if (_feeType == 0x00) {// Transfer fee
            for (uint256 i = 0; i < wrappedTokens[_wNFTAddress][_wNFTTokenId].fees.length; i ++){
                /////////////////////////////////////////
                // For Transfer Fee -0x00             ///  
                /////////////////////////////////////////
                if (wrappedTokens[_wNFTAddress][_wNFTTokenId].fees[i].feeType == 0x00){
                   // - get modelAddress.  Default feeModel adddress always live in
                   // protocolTechToken. When white list used it is possible override that model
                   address feeModel = protocolTechToken;
                    if  (protocolWhiteList != address(0)) {
                        feeModel = IAdvancedWhiteList(protocolWhiteList).getWLItem(
                            wrappedTokens[_wNFTAddress][_wNFTTokenId].fees[i].token).transferFeeModel;
                    }

                    // - get transfer list from external model by feetype(with royalties)
                    (ETypes.AssetItem[] memory assetItems, address[] memory from, address[] memory to) =
                        IFeeRoyaltyModel(feeModel).getTransfersList(
                            wrappedTokens[_wNFTAddress][_wNFTTokenId].fees[i],
                            wrappedTokens[_wNFTAddress][_wNFTTokenId].royalties,
                            _from, 
                            _to 
                        );
                    // - execute transfers
                    uint256 actualTransfered;
                    for (uint256 j = 0; j < to.length; j ++){
                        // if transfer receiver(to) = address(this) lets consider
                        // wNFT as receiver. in this case received amount
                        // will be added to collateral
                        if (to[j]== address(this)){
                            _updateCollateralInfo(
                              _wNFTAddress, 
                              _wNFTTokenId, 
                               assetItems[j]
                            ); 
                        }
                        actualTransfered = _transferSafe(assetItems[j], from[j], to[j]);
                        emit EnvelopFee(to[j], _wNFTAddress, _wNFTTokenId, actualTransfered); 
                    }
                }
                //////////////////////////////////////////
            }
            return true;
        }
    }


    /**
     * @dev This hook may be overriden in inheritor contracts for extend
     * base functionality.
     *
     * @param _wNFTAddress -wrapped token address
     * @param _wNFTTokenId -wrapped token id
     * 
     * must returns true for success unwrapping enable 
     */
    function _beforeUnWrapHook(address _wNFTAddress, uint256 _wNFTTokenId, bool _emergency) internal virtual returns (bool){
        uint256 transfered;
        for (uint256 i = 0; i < wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral.length; i ++) {
            if (wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[i].asset.assetType != ETypes.AssetType.EMPTY) {
                if (_emergency) {
                    // In case of something is wrong with any collateral (attack)
                    // user can use  this mode  for skip  malicious asset
                    transfered = _transferEmergency(
                        wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[i],
                        address(this),
                        wrappedTokens[_wNFTAddress][_wNFTTokenId].unWrapDestinition
                    );
                } else {
                    transfered = _transferSafe(
                        wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[i],
                        address(this),
                        wrappedTokens[_wNFTAddress][_wNFTTokenId].unWrapDestinition
                    );
                }

                // we collect info about contracts with not standard behavior
                if (transfered != wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[i].amount ) {
                    emit SuspiciousFail(
                        _wNFTAddress, 
                        _wNFTTokenId, 
                        wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[i].asset.contractAddress
                    );
                }

                // mark collateral record as returned
                wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral[i].asset.assetType = ETypes.AssetType.EMPTY;                
            }
            // dont pop due in some case it c can be very costly
            // https://docs.soliditylang.org/en/v0.8.9/types.html#array-members  
            // TODO add check  that wew  are not  in the  end of array 

            // For safe exit in case of low gaslimit
            if (
                gasleft() <= 1_000 &&
                i < wrappedTokens[_wNFTAddress][_wNFTTokenId].collateral.length - 1
             
                ) 
            {
                emit PartialUnWrapp(_wNFTAddress, _wNFTTokenId, i);
                return false;
            }
        }

        return true;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////

    function _mustTransfered(ETypes.AssetItem calldata _assetForTransfer) internal pure returns(uint256 mustTransfered) {
        // Available for wrap assets must be good transferable (stakable).
        // So for erc721  mustTransfered always be 1
        if (_assetForTransfer.asset.assetType == ETypes.AssetType.ERC721) {
            mustTransfered = 1;
        } else {
            mustTransfered = _assetForTransfer.amount;
        }
        return mustTransfered;
    }
     

    function _checkRule(bytes2 _rule, bytes2 _wNFTrules) internal view returns (bool) {
        return _rule == (_rule & _wNFTrules);
    }

    // 0x00 - TimeLock
    // 0x01 - TransferFeeLock
    function _checkLocks(address _wNFTAddress, uint256 _wNFTTokenId) internal view returns (bool) {
        // Lets check that inAsset
        ETypes.Lock[] memory _locks =  wrappedTokens[_wNFTAddress][_wNFTTokenId].locks; 
        for (uint256 i = 0; i < _locks.length; i ++) {
            // Time Lock check
            if (_locks[i].lockType == 0x00) {
                require(
                    _locks[i].param <= block.timestamp,
                    "TimeLock error"
                );
            }

            // Fee Lock check
            if (_locks[i].lockType == 0x01) {
                // Lets check this lock rule against each fee record
                for (uint256 j = 0; j < wrappedTokens[_wNFTAddress][_wNFTTokenId].fees.length; j ++){
                    // Fee Lock depend  only from Transfer Fee - 0x00
                    if ( wrappedTokens[_wNFTAddress][_wNFTTokenId].fees[j].feeType == 0x00) {
                        (uint256 _bal,) = getCollateralBalanceAndIndex(
                            _wNFTAddress, 
                            _wNFTTokenId,
                            ETypes.AssetType.ERC20,
                            wrappedTokens[_wNFTAddress][_wNFTTokenId].fees[j].token,
                            0
                        );
                        require(
                            _locks[i].param <= _bal,
                            "TransferFeeLock error"
                        );
                    }   

                }
                
            }
        }
        return true;
    }


    function _checkWrap(ETypes.INData calldata _inData, address _wrappFor) internal view returns (bool enabled){
        // Lets check that inAsset 
        // 0x0002 - this rule disable wrap already wrappednFT (NO matryoshka)
        enabled = !_checkRule(0x0002, getWrappedToken(
            _inData.inAsset.asset.contractAddress, 
            _inData.inAsset.tokenId).rules
            ) 
            && _wrappFor != address(this);
        // Check WhiteList Logic
        if  (protocolWhiteList != address(0)) {
            require(
                !IAdvancedWhiteList(protocolWhiteList).getBLItem(_inData.inAsset.asset.contractAddress),
                "WL:Asset disabled for wrap"
            );
            require(
                IAdvancedWhiteList(protocolWhiteList).rulesEnabled(_inData.inAsset.asset.contractAddress, _inData.rules),
                "WL:Some rules are disabled for this asset"
            );

            for (uint256 i = 0; i < _inData.fees.length; i ++){
                require(
                    IAdvancedWhiteList(protocolWhiteList).enabledForFee(
                        _inData.fees[i].token),
                        "WL:Some assets are not enabled for fee"
                    );
            }
        }    
        return enabled;
    }
    
    function _checkAddCollateral(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        ETypes.AssetItem[] calldata _collateral
    ) 
        internal 
        view 
        returns (bool enabled)
    {
        // Lets check wNFT rules 
        // 0x0008 - this rule disable add collateral
        enabled = !_checkRule(0x0008, getWrappedToken(_wNFTAddress, _wNFTTokenId).rules); 
        
        // Check WhiteList Logic
        if  (protocolWhiteList != address(0)) {
            for (uint256 i = 0; i < _collateral.length; i ++){
                if (_collateral[i].asset.assetType != ETypes.AssetType.EMPTY) {
                    require(
                        IAdvancedWhiteList(protocolWhiteList).enabledForCollateral(
                        _collateral[i].asset.contractAddress),
                        "WL:Some assets are not enabled for collateral"
                    );
                }
            }
        }
        return enabled;
    }

    function _checkCoreUnwrap(ETypes.AssetType _wNFTType, address _wNFTAddress, uint256 _wNFTTokenId) 
        internal 
        view 
        virtual 
        returns (address burnFor, uint256 burnBalance) 
    {
        
        // Lets wNFT rules 
        // 0x0001 - this rule disable unwrap wrappednFT 
        require(!_checkRule(0x0001, getWrappedToken(_wNFTAddress, _wNFTTokenId).rules),
            "UnWrapp forbidden by author"
        );

        if (_wNFTType == ETypes.AssetType.ERC721) {
            // Only token owner can UnWrap
            burnFor = IERC721Mintable(_wNFTAddress).ownerOf(_wNFTTokenId);
            require(burnFor == msg.sender, 
                'Only owner can unwrap it'
            ); 
            return (burnFor, burnBalance);

        } else if (_wNFTType == ETypes.AssetType.ERC1155) {
            burnBalance = IERC1155Mintable(_wNFTAddress).totalSupply(_wNFTTokenId);
            burnFor = msg.sender;
            require(
                burnBalance ==
                IERC1155Mintable(_wNFTAddress).balanceOf(burnFor, _wNFTTokenId)
                ,'ERC115 unwrap available only for all totalSupply'
            );
            return (burnFor, burnBalance);
            
        } else {
            revert UnSupportedAsset(ETypes.AssetItem(ETypes.Asset(_wNFTType,_wNFTAddress),_wNFTTokenId, 0));
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "IERC1155Receiver.sol";
import "ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
    ) external returns (bytes4);

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
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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
pragma solidity 0.8.11;
import "LibEnvelopTypes.sol";

interface IFeeRoyaltyModel {
    
    function registerModel() external;
    
    function getTransfersList(
        ETypes.Fee calldata _fee,
        ETypes.Royalty[] calldata _royalties,
        address _from, 
        address _to
    ) external view returns (
      ETypes.AssetItem[] memory, 
      address[] memory, 
      address[] memory
   );
}

// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. 
pragma solidity 0.8.11;

library ETypes {

    enum AssetType {EMPTY, NATIVE, ERC20, ERC721, ERC1155, FUTURE1, FUTURE2, FUTURE3}
    
    struct Asset {
        AssetType assetType;
        address contractAddress;
    }

    struct AssetItem {
        Asset asset;
        uint256 tokenId;
        uint256 amount;
    }

    struct NFTItem {
        address contractAddress;
        uint256 tokenId;   
    }

    struct Fee {
        bytes1 feeType;
        uint256 param;
        address token; 
    }

    struct Lock {
        bytes1 lockType;
        uint256 param; 
    }

    struct Royalty {
        address beneficiary;
        uint16 percent;
    }

    struct WNFT {
        AssetItem inAsset;
        AssetItem[] collateral;
        address unWrapDestinition;
        Fee[] fees;
        Lock[] locks;
        Royalty[] royalties;
        bytes2 rules;

    }

    struct INData {
        AssetItem inAsset;
        address unWrapDestinition;
        Fee[] fees;
        Lock[] locks;
        Royalty[] royalties;
        AssetType outType;
        uint256 outBalance;      //0- for 721 and any amount for 1155
        bytes2 rules;

    }

    struct WhiteListItem {
        bool enabledForFee;
        bool enabledForCollateral;
        bool enabledRemoveFromCollateral;
        address transferFeeModel;
    }

    struct Rules {
        bytes2 onlythis;
        bytes2 disabled;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

//import "IERC721Enumerable.sol";
import "LibEnvelopTypes.sol";

interface IWrapper  {

    event WrappedV1(
        address indexed inAssetAddress,
        address indexed outAssetAddress, 
        uint256 indexed inAssetTokenId, 
        uint256 outTokenId,
        address wnftFirstOwner,
        uint256 nativeCollateralAmount,
        bytes2  rules
    );

    event UnWrappedV1(
        address indexed wrappedAddress,
        address indexed originalAddress,
        uint256 indexed wrappedId, 
        uint256 originalTokenId, 
        address beneficiary, 
        uint256 nativeCollateralAmount,
        bytes2  rules 
    );

    event CollateralAdded(
        address indexed wrappedAddress,
        uint256 indexed wrappedId,
        uint8   assetType,
        address collateralAddress,
        uint256 collateralTokenId,
        uint256 collateralBalance
    );

    event PartialUnWrapp(
        address indexed wrappedAddress,
        uint256 indexed wrappedId,
        uint256 lastCollateralIndex
    );
    event SuspiciousFail(
        address indexed wrappedAddress,
        uint256 indexed wrappedId, 
        address indexed failedContractAddress
    );

    event EnvelopFee(
        address indexed receiver,
        address indexed wNFTConatract,
        uint256 indexed wNFTTokenId,
        uint256 amount
    );

    function wrap(
        ETypes.INData calldata _inData, 
        ETypes.AssetItem[] calldata _collateral, 
        address _wrappFor
    ) 
        external 
        payable 
    returns (ETypes.AssetItem memory);

    function wrapUnsafe(
        ETypes.INData calldata _inData, 
        ETypes.AssetItem[] calldata _collateral, 
        address _wrappFor
    ) 
        external 
        payable
    returns (ETypes.AssetItem memory);

    function addCollateral(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        ETypes.AssetItem[] calldata _collateral
    ) external payable;

    function addCollateralUnsafe(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        ETypes.AssetItem[] calldata _collateral
    ) 
        external 
        payable;

    function unWrap(
        ETypes.AssetType _wNFTType, 
        address _wNFTAddress, 
        uint256 _wNFTTokenId
    ) external; 

    function unWrap(
        ETypes.AssetType _wNFTType, 
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        bool _isEmergency
    ) external;

    function chargeFees(
        address _wNFTAddress, 
        uint256 _wNFTTokenId, 
        address _from, 
        address _to,
        bytes1 _feeType
    ) 
        external  
        returns (bool);   

    ////////////////////////////////////////////////////////////////////// 
    
    function MAX_COLLATERAL_SLOTS() external view returns (uint256);
    function protocolTechToken() external view returns (address);
    function protocolWhiteList() external view returns (address);
    function trustedOperators(address _operator) external view returns (bool); 
    //function lastWNFTId(ETypes.AssetType _assetType) external view returns (ETypes.NFTItem); 

    function getWrappedToken(address _wNFTAddress, uint256 _wNFTTokenId) 
        external 
        view 
        returns (ETypes.WNFT memory);

    function getOriginalURI(address _wNFTAddress, uint256 _wNFTTokenId) 
        external 
        view 
        returns(string memory); 
    
    function getCollateralBalanceAndIndex(
        address _wNFTAddress, 
        uint256 _wNFTTokenId,
        ETypes.AssetType _collateralType, 
        address _erc,
        uint256 _tokenId
    ) external view returns (uint256, uint256);
   
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

//import "IERC721Enumerable.sol";
import "LibEnvelopTypes.sol";

interface IAdvancedWhiteList  {


    event WhiteListItemChanged(
        address indexed asset,
        bool enabledForFee,
        bool enabledForCollateral,
        bool enabledRemoveFromCollateral,
        address transferFeeModel
    );
    event BlackListItemChanged(
        address indexed asset,
        bool isBlackListed
    );
    function getWLItem(address _asset) external view returns (ETypes.WhiteListItem memory);
    function getWLItemCount() external view returns (uint256);
    function getBLItem(address _asset) external view returns (bool);
    function getBLItemCount() external view returns (uint256);
    function enabledForCollateral(address _asset) external view returns (bool);
    function enabledForFee(address _asset) external view returns (bool);
    function enabledRemoveFromCollateral(address _asset) external view returns (bool);
    function rulesEnabled(address _asset, bytes2 _rules) external view returns (bool);
    function validateRules(address _asset, bytes2 _rules) external view returns (bytes2);
}

// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. Wrapper - main protocol contract
pragma solidity 0.8.11;

import "SafeERC20.sol";
import "IERC20Extended.sol";
import "LibEnvelopTypes.sol";
import "IERC721Mintable.sol";
import "IERC1155Mintable.sol";
//import "ITokenService.sol";

abstract contract TokenService {
	using SafeERC20 for IERC20Extended;
    
    error UnSupportedAsset(ETypes.AssetItem asset);
	
    function _mintNFT(
        ETypes.AssetType _mint_type, 
        address _contract, 
        address _mintFor, 
        uint256 _tokenId, 
        uint256 _outBalance
    ) 
        internal 
        virtual
    {
        if (_mint_type == ETypes.AssetType.ERC721) {
            IERC721Mintable(_contract).mint(_mintFor, _tokenId);
        } else if (_mint_type == ETypes.AssetType.ERC1155) {
            IERC1155Mintable(_contract).mint(_mintFor, _tokenId, _outBalance);
        }
    }

    function _burnNFT(
        ETypes.AssetType _burn_type, 
        address _contract, 
        address _burnFor, 
        uint256 _tokenId, 
        uint256 _balance
    ) 
        internal
        virtual 
    {
        if (_burn_type == ETypes.AssetType.ERC721) {
            IERC721Mintable(_contract).burn(_tokenId);

        } else if (_burn_type == ETypes.AssetType.ERC1155) {
            IERC1155Mintable(_contract).burn(_burnFor, _tokenId, _balance);
        }
        
    }

    function _transfer(
        ETypes.AssetItem memory _assetItem,
        address _from,
        address _to
    ) internal virtual returns (bool _transfered){
        if (_assetItem.asset.assetType == ETypes.AssetType.NATIVE) {
            (bool success, ) = _to.call{ value: _assetItem.amount}("");
            require(success, "transfer failed");
            _transfered = true; 
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC20) {
            require(IERC20Extended(_assetItem.asset.contractAddress).balanceOf(_from) <= _assetItem.amount, "UPS!!!!");
            IERC20Extended(_assetItem.asset.contractAddress).safeTransferFrom(_from, _to, _assetItem.amount);
            _transfered = true;
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC721) {
            IERC721Mintable(_assetItem.asset.contractAddress).transferFrom(_from, _to, _assetItem.tokenId);
            _transfered = true;
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC1155) {
            IERC1155Mintable(_assetItem.asset.contractAddress).safeTransferFrom(_from, _to, _assetItem.tokenId, _assetItem.amount, "");
            _transfered = true;
        } else {
            revert UnSupportedAsset(_assetItem);
        }
        return _transfered;
    }

    function _transferSafe(
        ETypes.AssetItem memory _assetItem,
        address _from,
        address _to
    ) internal virtual returns (uint256 _transferedValue){
        //TODO   think about try catch in transfers
        uint256 balanceBefore;
        if (_assetItem.asset.assetType == ETypes.AssetType.NATIVE) {
            balanceBefore = _to.balance;
            (bool success, ) = _to.call{ value: _assetItem.amount}("");
            require(success, "transfer failed");
            _transferedValue = _to.balance - balanceBefore;
        
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC20) {
            balanceBefore = IERC20Extended(_assetItem.asset.contractAddress).balanceOf(_to);
            if (_from == address(this)){
                IERC20Extended(_assetItem.asset.contractAddress).safeTransfer(_to, _assetItem.amount);
            } else {
                IERC20Extended(_assetItem.asset.contractAddress).safeTransferFrom(_from, _to, _assetItem.amount);
            }    
            _transferedValue = IERC20Extended(_assetItem.asset.contractAddress).balanceOf(_to) - balanceBefore;
        
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC721 &&
            IERC721Mintable(_assetItem.asset.contractAddress).ownerOf(_assetItem.tokenId) == _from) {
            balanceBefore = IERC721Mintable(_assetItem.asset.contractAddress).balanceOf(_to); 
            IERC721Mintable(_assetItem.asset.contractAddress).transferFrom(_from, _to, _assetItem.tokenId);
            if (IERC721Mintable(_assetItem.asset.contractAddress).ownerOf(_assetItem.tokenId) == _to &&
                IERC721Mintable(_assetItem.asset.contractAddress).balanceOf(_to) - balanceBefore == 1
                ) {
                _transferedValue = 1;
            }
        
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC1155) {
            balanceBefore = IERC1155Mintable(_assetItem.asset.contractAddress).balanceOf(_to, _assetItem.tokenId);
            IERC1155Mintable(_assetItem.asset.contractAddress).safeTransferFrom(_from, _to, _assetItem.tokenId, _assetItem.amount, "");
            _transferedValue = IERC1155Mintable(_assetItem.asset.contractAddress).balanceOf(_to, _assetItem.tokenId) - balanceBefore;
        
        } else {
            revert UnSupportedAsset(_assetItem);
        }
        return _transferedValue;
    }

    // This function must never revert. Use it for unwrap in case some 
    // collateral transfers are revert
    function _transferEmergency(
        ETypes.AssetItem memory _assetItem,
        address _from,
        address _to
    ) internal virtual returns (uint256 _transferedValue){
        //TODO   think about try catch in transfers
        uint256 balanceBefore;
        if (_assetItem.asset.assetType == ETypes.AssetType.NATIVE) {
            balanceBefore = _to.balance;
            (bool success, ) = _to.call{ value: _assetItem.amount}("");
            //require(success, "transfer failed");
            _transferedValue = _to.balance - balanceBefore;
        
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC20) {
            if (_from == address(this)){
               (bool success, ) = _assetItem.asset.contractAddress.call(
                   abi.encodeWithSignature("transfer(address,uint256)", _to, _assetItem.amount)
               );
            } else {
                (bool success, ) = _assetItem.asset.contractAddress.call(
                    abi.encodeWithSignature("transferFrom(address,address,uint256)", _from,  _to, _assetItem.amount)
                );
            }    
            _transferedValue = _assetItem.amount;
        
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC721) {
            (bool success, ) = _assetItem.asset.contractAddress.call(
                abi.encodeWithSignature("transferFrom(address,address,uint256)", _from,  _to, _assetItem.tokenId)
            );
            _transferedValue = 1;
        
        } else if (_assetItem.asset.assetType == ETypes.AssetType.ERC1155) {
            (bool success, ) = _assetItem.asset.contractAddress.call(
                abi.encodeWithSignature("safeTransferFrom(address,address,uint256,uint256,bytes)", _from, _to, _assetItem.tokenId, _assetItem.amount, "")
            );
            _transferedValue = _assetItem.amount;
        
        } else {
            revert UnSupportedAsset(_assetItem);
        }
        return _transferedValue;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "IERC20.sol";

interface IERC20Extended is  IERC20 {
     function mint(address _to, uint256 _value) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "IERC721Metadata.sol";

interface IERC721Mintable is  IERC721Metadata {
     function mint(address _to, uint256 _tokenId) external;
     function burn(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "IERC1155MetadataURI.sol";

interface IERC1155Mintable is  IERC1155MetadataURI {
     function mint(address _to, uint256 _tokenId, uint256 _amount) external;
     function burn(address _to, uint256 _tokenId, uint256 _amount) external;
     function totalSupply(uint256 _id) external view returns (uint256); 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. 
pragma solidity 0.8.11;

import "LibEnvelopTypes.sol";


interface ITokenService {

    error UnSupportedAsset(ETypes.AssetItem asset);
	
	function mintNFT(
        ETypes.AssetType _mint_type, 
        address _contract, 
        address _mintFor, 
        uint256 _tokenId, 
        uint256 _outBalance
    ) 
        external;
    

    function burnNFT(
        ETypes.AssetType _burn_type, 
        address _contract, 
        address _burnFor, 
        uint256 _tokenId, 
        uint256 _balance
    ) 
        external; 

    function transfer(
        ETypes.AssetItem memory _assetItem,
        address _from,
        address _to
    ) external  returns (bool _transfered);

    function transferSafe(
        ETypes.AssetItem memory _assetItem,
        address _from,
        address _to
    ) external  returns (uint256 _transferedValue);

    // This function must never revert. Use it for unwrap in case some 
    // collateral transfers are revert
    function transferEmergency(
        ETypes.AssetItem memory _assetItem,
        address _from,
        address _to
    ) external  returns (uint256 _transferedValue);
}