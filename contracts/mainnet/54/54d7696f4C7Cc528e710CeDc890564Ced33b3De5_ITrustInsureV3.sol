/* Copyright (C) 2021 NexusMutual.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.7.5;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
interface IDistributor is IERC721{
  enum ClaimStatus { IN_PROGRESS, ACCEPTED, REJECTED }

  event ClaimPayoutRedeemed (
    uint indexed coverId,
    uint indexed claimId,
    address indexed receiver,
    uint amountPaid,
    address coverAsset
  );

  event ClaimSubmitted (
    uint indexed coverId,
    uint indexed claimId,
    address indexed submitter
  );

  event CoverBought (
    uint indexed coverId,
    address indexed buyer,
    address indexed contractAddress,
    uint feePercentage,
    uint coverPrice
  );


  function buyCover (
    address contractAddress,
    address coverAsset,
    uint sumAssured,
    uint16 coverPeriod,
    uint8 coverType,
    uint maxPriceWithFee,
    bytes calldata data
  )
    external
    payable
    returns (uint);


  function submitClaim(
    uint tokenId,
    bytes calldata data
  )
    external
    
    returns (uint);
  
  function redeemClaim(
    uint256 tokenId,
    uint claimId
  )
    external;

 
  function executeCoverAction(uint tokenId, uint assetAmount, address asset, uint8 action, bytes calldata data)
    external
    payable
  returns (bytes memory response, uint withheldAmount);

  function getCover(uint tokenId)
  external
  view
  returns (
    uint8 status,
    uint sumAssured,
    uint16 coverPeriod,
    uint validUntil,
    address contractAddress,
    address coverAsset,
    uint premiumInNXM,
    address memberAddress
  );

  function getPayoutOutcome(uint claimId)
  external
  view
  returns (ClaimStatus status, uint amountPaid, address coverAsset);
  
  function approveNXM(address spender, uint256 amount) external; 

  function withdrawNXM(address recipient, uint256 amount) external; 
 
  function switchMembership(address newAddress) external ;

  function sellNXM(uint nxmIn, uint minEthOut) external;
 
  function setBuysAllowed(bool _buysAllowed) external;
  
  function setTreasury(address payable _treasury) external;

  function setFeePercentage(uint _feePercentage) external;

  // function ownerOf(uint256 tokenId) external override view returns (address);
  // function isApprovedForAll(address owner, address operator) external override view returns (bool);
  function owner() external view returns (address);
  function transferOwnership(address newOwner) external;

}

/* Copyright (C) 2021 NexusMutual.io
  This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
  This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
  You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/ */

pragma solidity ^0.7.4;

interface INXMaster {

    function masterInitialized() external view returns(bool);

    function isPause() external view returns(bool check);

    function isMember(address _add) external view returns(bool);

    function getLatestAddress(bytes2 _contractName) external view returns(address payable contractAddress);

    function tokenAddress() external view returns (address);

    function closeClaim(uint _claimId) external;
}

pragma solidity 0.7.6;
pragma abicoder v2;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./../External/INXMaster.sol";
import "./../External/IDistributor.sol";


/// @author iTrust Dev Team
/// @title Insurance contract for exchanges to purchase Nexus Mutual cover
contract ITrustInsureV3
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20 for IERC20;
    enum CoverClaimStatus { 
        NoActiveClaim, 
        Processing, 
        PaymentReady, 
        Complete, 
        Rejected 
    }

    struct Exchange {
        bool active;
        uint256 feePercentage;
        address payable treasuryAddress;
        string name;
        uint256[] coverIds;
    }

    struct User {
        address walletAddress;
        uint256[] coverIds;
    }

    struct CoverData {
        uint256 coverId;
        uint8 status;
        uint256 sumAssured;
        uint16 coverPeriod;
        uint256 validUntil;
        address contractAddress;
        address coverAsset;
        uint256 premiumInNXM;
        address memberAddress;
        uint256 claimId;        
        uint256 claimStatus;
        uint256 claimAmountPaid;
        address claimAsset;    
        bool claimsAllowed;
        bool claimed;
        bool iTrustOwned;
    }

    uint8 internal constant FALSE = 0;
    uint8 internal constant TRUE = 1;
    bool internal _paused;
    uint256 internal _iTrustFeePercentage;
    uint256 public addressRequestFee;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address payable public iTrustTreasury;
    address internal _nxmTokenAddress;
    address internal _distributorAddress;
    address[] internal _exchangeList;
    
    string[] internal _userIds;
    uint8 internal LOCKED;
    mapping (address => uint8) internal _adminList;
    mapping(address => Exchange) internal _exchanges;
    mapping(uint256 => address) internal _exchangeLocations;
    mapping(address => string) internal _addressRequests;
    mapping(string => User) internal _userPolicies;
    mapping(uint256 => uint256) internal _claimIds; //key is coverid
    mapping(uint256 => uint256) internal _claimedAmounts; //key is coverid
    mapping(uint256 => uint8) internal _claimCount;

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;
   
    uint constant DIV_PRECISION = 10000;

    event ITrustClaimPayoutRedeemed (
        uint indexed coverId,
        uint indexed claimId,
        address indexed receiver,
        uint amountPaid,
        address coverAsset
    );

    event ITrustCoverBought(
        uint256 indexed coverId,
        string exchange,
        string guid,
        address buyer
    );

    function nonReentrant() internal {
        require(LOCKED == FALSE, "reentrant call");        
    }

    function onlyAdmin() internal view {
        require(
            _adminList[msg.sender] ==TRUE,
            "not an admin"
        );
    }

    function ifNotPaused() internal view{
        require(!_paused, "Contract Frozen");
    }
    
    /// @dev - reinitialises distributor in contract
    /// @param distributorAddress - address of distributor
    function setDistributor(address distributorAddress) 
        external 
    {
        onlyAdmin();
        _distributorAddress = distributorAddress;
    }
    
    /// @dev list of users    
    function getGuids() external view returns (string[] memory) {
        return _userIds;
    }
    
    /// @dev extracts price from cover data
    function _getCoverPrice(bytes calldata data) internal pure returns (uint256) {
        uint256 price;
        uint256 priceInNXM;
        uint256 expiresAt;
        uint256 generatedAt;
        uint8 v;
        bytes32 r;
        bytes32 s;
        (price, priceInNXM, expiresAt, generatedAt, v, r, s) = abi.decode(
            data,
            (uint256, uint256, uint256, uint256, uint8, bytes32, bytes32)
        );
        return price;
    }

    /// @dev buy cover on distributor contract
    /// @param exchangeAddress - address of exchange purchasing cover
    /// @param contractAddress - address of contract for cover
    /// @param coverAsset - address of asset
    /// @param sumAssured - amount of cover,
    /// @param coverPeriod - length of cover
    /// @param coverType - type of cover
    /// @param userGUID - user identifier returned by quote api
    /// @param coverData - signature of quote returned by quote api
    /// @return cover id for purchased cover
    function buyCover(
        address exchangeAddress,
        address contractAddress,
        address coverAsset,
        uint256 sumAssured,
        uint16 coverPeriod,
        uint8 coverType,
        string memory userGUID,
        bytes calldata coverData
    ) 
        external 
        payable        
    returns (uint256) {
        nonReentrant();
        ifNotPaused();
        LOCKED = TRUE;
        
        uint coverPrice = _getCoverPrice(coverData);
        uint priceIncludingFee = _iTrustFeePercentage.mul(coverPrice).div(DIV_PRECISION).add(coverPrice);

        if(coverAsset == ETH){
            require(msg.value == priceIncludingFee , "Eth Sent and Price Mismatch" );
        } else {
            IERC20 token = IERC20(coverAsset);
            uint balance = token.balanceOf(msg.sender);
            require(balance >= priceIncludingFee , "Token Balance and Price Mismatch" );
            token.safeTransferFrom(msg.sender, address(this), priceIncludingFee);
            token.approve(address(_distributorAddress), priceIncludingFee);
        }
         
        Exchange memory purchaseExchange = _exchanges[address(exchangeAddress)];
        require(
            purchaseExchange.treasuryAddress != address(0) && purchaseExchange.active,
            "iTrust: Inactive exchange"
        );
        
        uint256 coverId = getDistributorContract().buyCover{ value: msg.value }(
                contractAddress,
                coverAsset,
                sumAssured,
                coverPeriod,
                coverType,
                priceIncludingFee, //max cover price with fee
                coverData
            );
        
        _saveCoverDetails(userGUID, coverId, purchaseExchange.treasuryAddress);

        //send funds to exchange
        if(coverAsset == ETH){
            require(address(this).balance >= msg.value.sub(coverPrice), "iTrust: Insufficient ETH left for commission");
        } else {
            require(IERC20(coverAsset).balanceOf(address(this)) >= priceIncludingFee.sub(coverPrice), "iTrust: Insufficient Token Balance left for commission");
        }
        
        uint256 exchangeCommission;
        if (purchaseExchange.feePercentage > 0) {
             exchangeCommission = coverPrice
                 .mul(purchaseExchange.feePercentage)
                 .div(DIV_PRECISION);
        }        
        
        if(coverAsset == ETH){
            iTrustTreasury.transfer(msg.value.sub(coverPrice).sub(exchangeCommission));
        } else {
            // TODO:: check balance amounts
            IERC20(coverAsset).transfer(iTrustTreasury, priceIncludingFee.sub(coverPrice).sub(exchangeCommission));
        }
        

        if (exchangeCommission > 0) {                                        
            if(coverAsset == ETH){
                purchaseExchange.treasuryAddress.transfer(exchangeCommission);
            } else {
                IERC20(coverAsset).transfer(purchaseExchange.treasuryAddress, exchangeCommission);
            }
        }

        //transfer NFT to itrust Treasury
        getDistributorContract().safeTransferFrom(
            address(this),
            iTrustTreasury,
            coverId
        );   

        emit ITrustCoverBought(
            coverId,
            purchaseExchange.name,
            userGUID,
            msg.sender
        );

        LOCKED = FALSE;    
        return coverId;
    }

    function _saveCoverDetails(
        string memory userGUID,
        uint256 coverId,
        address exchangeAddress
    ) internal {
        _userPolicies[userGUID].coverIds.push(coverId);
        _exchanges[exchangeAddress].coverIds.push(coverId);
        _userIds.push(userGUID);
    }

    /// @dev See {IERC721Receiver-onERC721Received}.
    /// Always returns `IERC721Receiver.onERC721Received.selector`.
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) 
        public 
        returns (bytes4) 
    {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    /// @notice adds or updates exchange
    /// @param exchangeAddress - treasury of exchange
    /// @param feePercentage - percentage of commission
    /// @param active - flag
    /// @param name - name of exchange
    function addOrUpdateExchange(
        address payable exchangeAddress,
        uint256 feePercentage,
        bool active,
        string memory name
    ) 
        external 
    {
        onlyAdmin();
        if (_exchanges[exchangeAddress].treasuryAddress == address(0)) {
            _exchangeList.push(exchangeAddress);
        }
        _exchanges[exchangeAddress] = Exchange({
            feePercentage: feePercentage,
            treasuryAddress: exchangeAddress,
            active: active,
            name: name,
            coverIds: new uint256[](0)
        });
    }

    /// @notice sets commission for exchange
    /// @param exchangeAddress - address for exchange
    /// @param feePercentage - commision percentage
    function setExchangeFeePercentage(
        address exchangeAddress,
        uint256 feePercentage
    ) 
        external 
    {
        onlyAdmin();
        _exchanges[exchangeAddress].feePercentage = feePercentage;
    }

    /// @notice sets exchangeto active
    /// @param exchangeAddress - address for exchange
    function activateExchange(address exchangeAddress) 
        external 
    {
        onlyAdmin();
        ifNotPaused();
        _exchanges[exchangeAddress].active = true;
    }

    /// @notice sets exchangeto inactive
    /// @param exchangeAddress - address for exchange
    function deactivateExchange(address exchangeAddress) 
        external 
    {
        onlyAdmin();
        _exchanges[exchangeAddress].active = false;
    }

    /// @notice get details of exchange
    /// @param exchangeAddress - address for exchange
    /// @return details of exchange
    function getExchangeDetails(address exchangeAddress)
        external
        view   
        returns (Exchange memory)
    {
        onlyAdmin();        
        return _exchanges[exchangeAddress];
    }

    /// @notice get details of all exchanges
    /// @return details of all exchanges
    function getAllExchanges()
        external
        view      
        returns (Exchange[] memory)
    {
        onlyAdmin();
        
        Exchange[] memory ret = new Exchange[](_exchangeList.length);
        for (uint256 i = 0; i < _exchangeList.length; i++) {
            ret[i] = _exchanges[_exchangeList[i]];
        }
        return ret;
    }

    /// @notice Returns the commission percentage held in the distributor
    /// @return percentage of commission
    function getFeePercentage() external view returns (uint256) {
        return _iTrustFeePercentage;
    }

    /// @notice sets itrust treasury address
    /// @param iTrustTreasuryAddress - new address
    function setItrustTreasury(address payable iTrustTreasuryAddress)
        external
    {
        onlyAdmin();
        ifNotPaused();
        iTrustTreasury = iTrustTreasuryAddress;
    }

    /// @notice submits new claim to nexus
    /// @param userGUID - identifier of user
    /// @param coverId - id for clover to submit claim against
    /// @param coverClaimData - extra claim data abi encoded
    /// @return
    function submitClaim(
        string memory userGUID,
        uint256 coverId,
        bytes calldata coverClaimData
    ) 
        external 
        returns (uint256) 
    {        
        ifNotPaused();
        CoverData memory cover = getCoverDataForCover(coverId);        
        require(cover.iTrustOwned, "submit NFT");
        require(cover.claimsAllowed 
            && _userOwnsCover(userGUID, coverId) == TRUE 
            && msg.sender == _userPolicies[userGUID].walletAddress);//check cover
         
        uint256 claimId =
            getDistributorContract().submitClaim(coverId, coverClaimData);
        _claimIds[coverId] = claimId;
        _claimCount[coverId] = _claimCount[coverId] + TRUE;
        return claimId;
    }

    function _userOwnsCover(string memory userGUID, uint coverId) internal view returns (uint8) {
        uint16 i = 0;
        while (i < _userPolicies[userGUID].coverIds.length) {
            if (_userPolicies[userGUID].coverIds[i] == coverId) {
                return TRUE;
            }
            i++;
        }
        return FALSE;
    }

    function getCoverDataForCover(uint coverId) public view returns (CoverData memory cover){
        cover = CoverData(
            coverId,
            /*status:*/ 0, 
            /*sumAssured:*/ 0, 
            /*coverPeriod:*/ 0, 
            /*validUntil:*/ 0, 
            /*contactAddress:*/ address(0), 
            /*coverAsset:*/ address(0), 
            /*premiumInNXM:*/ 0, 
            /*memberAddress:*/ address(0), 
            /*claimId:*/ 0, 
            /*claimStatus:*/ uint256(CoverClaimStatus.NoActiveClaim),
            /*claimAmountPaid:*/ 0,
            /*claimAsset:*/ address(0),
            /*claimsAllowed:*/ false,
            /*claimed:*/ false,
            /*iTrustOwned:*/ false    
        );       
        
        (
            cover.status,
            cover.sumAssured,
            cover.coverPeriod,
            cover.validUntil,
            cover.contractAddress,
            cover.coverAsset,
            cover.premiumInNXM,
            cover.memberAddress
        ) = getDistributorContract().getCover(coverId);

        
        if (_claimIds[cover.coverId] != uint256(0)) {            
            IDistributor.ClaimStatus status;
            cover.claimStatus = uint256(CoverClaimStatus.Processing);
            cover.claimId = _claimIds[coverId];
            (
                status,
                cover.claimAmountPaid,
                cover.claimAsset
            ) = getDistributorContract().getPayoutOutcome(_claimIds[coverId]);

            if ( _claimedAmounts[coverId] != uint256(0) &&
                status == IDistributor.ClaimStatus.ACCEPTED) {

                cover.claimStatus = uint256(CoverClaimStatus.Complete);
                cover.claimed = true;

            } else if (
                status == IDistributor.ClaimStatus.ACCEPTED &&                
                _claimedAmounts[coverId] == uint256(0)
            ) {

                cover.claimStatus = uint256(CoverClaimStatus.PaymentReady);

            } else if ( status == IDistributor.ClaimStatus.REJECTED ) {

                cover.claimStatus = uint256(CoverClaimStatus.Rejected);

            }
        }
        cover.claimsAllowed = (_canMakeClaim(cover) == TRUE); 

        if(!cover.claimed){
            cover.iTrustOwned = _isItrustOwner(coverId);
        }               
        
        return cover;
    }
    

    /// @notice returns cover held for a user
    /// @param userGUID - user identifier
    /// @return covers - array of covers held by user
    function getCoverData(string memory userGUID)
        external
        view        
        returns (CoverData[] memory covers)
    {
        onlyAdmin();
        
        uint256 i;
        
        CoverData[] memory userCover = new CoverData[](_userPolicies[userGUID].coverIds.length);      
                 
        while (i < _userPolicies[userGUID].coverIds.length) {                            
            userCover[i] = getCoverDataForCover(_userPolicies[userGUID].coverIds[i]);            
            i++;
        }
        return userCover;
    }

    /// @notice creates a wallet registration request
    /// @dev pays eth fee to itrust treasury
    /// @param uid - user identifier
    function addAddressRequest(string memory uid) 
        external 
        payable 
    {        
        ifNotPaused();
        require(
            msg.value >= addressRequestFee,
            "Insufficient ETH"
        );
       
        _addressRequests[msg.sender] = uid;

        iTrustTreasury.transfer(msg.value);
        
    }

    /// @dev  Checks if the current sender has a request matching the _uid
    /// @param uid user identifer
    /// @return boolean
    function hasAddressRequest(string memory uid) external view returns (bool) {
        return
            keccak256(abi.encodePacked(_addressRequests[msg.sender])) ==
            keccak256(abi.encodePacked(uid));
    }

    /// @dev Checks if an _address / _uid combo matches
    /// @param uid - user identifer
    /// @param newAddress - address to check validity
    /// @return boolean
    function isValidAddressRequest(string memory uid, address newAddress)
        external
        view
        returns (bool)
    {
        onlyAdmin();
        
        return
            keccak256(abi.encodePacked(_addressRequests[newAddress])) ==
            keccak256(abi.encodePacked(uid));
    }

    /// @notice validates new address request
    /// @dev Checks if an _address / _uid combo matches
    /// @param uid - user identifer
    /// @param newAddress - address to check validity
     function validateAddressRequest(string memory uid, address newAddress)
        external
    {
        onlyAdmin();
        ifNotPaused();
        require(
            (keccak256(abi.encodePacked(_addressRequests[newAddress])) ==
                keccak256(abi.encodePacked(uid))),
            "address missmatch"
        );

        delete _addressRequests[newAddress];

        _userPolicies[uid].walletAddress = newAddress;
    }

    /**
     * @dev Pauses the vault
     */
    function pause() external  {
        onlyAdmin();
        _paused = true;
    }

    /**
     * @dev Unpauses the vault
     */
    function unpause() external {
        onlyAdmin();
        _paused = false;
    }

    /**
     * @dev add new admin
     */
    function addAdminAddress(address newAddress) external  {
        onlyAdmin();
        require(_adminList[newAddress] ==FALSE);
        _adminList[newAddress] =TRUE;
    }

    /**
     * @dev revoke admin
     */
    function revokeAdminAddress(address newAddress) external {
        onlyAdmin();
        require(msg.sender != newAddress);
        _adminList[newAddress] =FALSE;
    }

    /**
     * @dev Modify the address request fee
     */
    function setaddressRequestFee(uint256 fee) 
        external 
    {
        onlyAdmin();
        
        addressRequestFee = fee;
    }

    /**
     * @dev required to be allow for receiving ETH claim payouts
     */
    receive() external payable {}


    /// @notice withdraws NXM deposit
    /// @dev only Admin
    /// @param amount - amount to withdraw    
    function withdrawNXM(uint256 amount) 
        external 
    {
        onlyAdmin();
        ifNotPaused();
        
        getDistributorContract().withdrawNXM(iTrustTreasury, amount);
    }

    /// @notice redeems claim amount
    /// @dev Checks if an _address / _uid combo matches
    /// @param userId - user identifer
    /// @param coverId - cover claiming against
    function redeemClaim(string memory userId, uint256 coverId) 
        external
    {
        nonReentrant();        
        LOCKED = TRUE;
        require( msg.sender == _userPolicies[userId].walletAddress);
        
        (   
            IDistributor.ClaimStatus claimStatus, 
            uint amountPaid, 
            address coverAsset
        ) = getDistributorContract().getPayoutOutcome(_claimIds[coverId]);
        require(claimStatus == IDistributor.ClaimStatus.ACCEPTED &&
                amountPaid > uint(0) &&
                _claimedAmounts[coverId] == uint(0));

        _claimedAmounts[coverId] = amountPaid;
        getDistributorContract().redeemClaim(coverId, _claimIds[coverId]);
        if (coverAsset == ETH) {
            payable(msg.sender).transfer(amountPaid);            
        } else {
            IERC20 erc20 = IERC20(coverAsset);
            erc20.safeTransfer(msg.sender, amountPaid);
        }
        
        emit ITrustClaimPayoutRedeemed(coverId, _claimIds[coverId], msg.sender, amountPaid, coverAsset);
        LOCKED = FALSE;
    }


    /// @notice Can user make claim on cover
    /// @dev internal
    /// @param cover - cover to check
    /// @return boolean true or false
    function _canMakeClaim(CoverData memory cover) internal view returns (uint8){
        if(_claimCount[cover.coverId] >= 2){
            return FALSE;
        }
        if(cover.claimId != 0 && 
            cover.claimStatus == uint256(CoverClaimStatus.Processing)) {
             
            return FALSE;
        }    
        if(cover.claimId != 0 && 
            cover.claimStatus == uint256(CoverClaimStatus.PaymentReady)) {
            return FALSE;
        }      
        if(cover.claimed) {
            return FALSE;
        }

        return TRUE;
    }

    /// @notice gets NXM balance of distributor
    /// @return uint balance in wei
    function NXMBalance() 
        external 
        view 
        returns (uint) 
    {
        onlyAdmin();
        
        return IERC20(_nxmTokenAddress).balanceOf(_distributorAddress);    
    }      

    /// @notice does itrust have approval to spend nft
    /// @return boolean
    function isTreasuryApproved() 
        external 
        view 
        returns (bool) 
    {
        onlyAdmin();
        
        
        return getDistributorContract().isApprovedForAll(address(iTrustTreasury), address(this)); 
    }

    /// @notice does itrust have custody of the token
    /// @return boolean
    function _isItrustOwner(uint coverId) internal view returns (bool) {
        
        return (getDistributorContract().ownerOf(coverId) == iTrustTreasury); 
    }  

    /// @notice withdraws NFt from itrust treasury
    function withdrawNFT(string memory userGUID, uint coverId) external {
        nonReentrant();
        LOCKED = TRUE;
        require(
            _userOwnsCover(userGUID, coverId) == TRUE &&
            msg.sender == _userPolicies[userGUID].walletAddress);

        IERC721 nftToken = IERC721(_distributorAddress);
        nftToken.safeTransferFrom(iTrustTreasury, payable(_userPolicies[userGUID].walletAddress), coverId);
        LOCKED = FALSE;
    }

    /// @notice transfers ownership of the distributor contract
    function setNewDistributorOwner(address newOwner) external {
        onlyAdmin();
        
        getDistributorContract().transferOwnership(newOwner);
    }

    function getDistributorContract() internal view returns (IDistributor) {
        return IDistributor(_distributorAddress);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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