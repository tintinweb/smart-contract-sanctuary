// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./ILendingPool.sol";
import "./IWETHGateway.sol";

contract MyAaveToken is Ownable {
    using SafeMath for uint256;
    using Address for address;

    struct Lender{
        address lenderAddress;
        address assetAddress;
        uint256 lendedAmount;
        uint256 lenderProfit;
        EAmountType amountType;
        bool isLended;
        uint256 lendedAt;
        uint256 lastRewardGivenAt;
    }

    enum EAmountType{
        None,
        Coin,
        Token
    }

    uint256 public feePercentage;

    address public leadingPoolAddress;
    address public wETHGatewayAddress;

    mapping (address => bool) public assets;
    mapping (address => address) public variableDebtBearings;
    mapping (address => address) public stableDebtBearings;
    mapping (address => address) public interestBearings;

    mapping (bytes32 => Lender) public lenders;


    constructor(address _leadingPoolAddress, address _wETHGatewayAddress,uint256 _feePercentage){
        leadingPoolAddress = _leadingPoolAddress;
        wETHGatewayAddress = _wETHGatewayAddress;
        feePercentage = _feePercentage;
    }

    function getTokenLender(address _assetAddress, address _lenderAddress) public view returns(Lender memory){
        bytes32 uniqueKey = getPrivateUniqueKey(_assetAddress, _lenderAddress);

        return lenders[uniqueKey];
    }

    function getCoinLender(address _lenderAddress) public view returns(Lender memory){
        bytes32 uniqueKey = getPrivateUniqueKey(_lenderAddress);

        return lenders[uniqueKey];
    }

    function depositToken(address _assetAddress, uint256 _amount, uint16 _referralCode) external{
        if (!assets[_assetAddress]){
            revert("asset not allow");
        }

        if (_amount <= 0){
            revert("amount should be grater then 0");
        }

        IERC20 erc20 = IERC20(_assetAddress);
        ILendingPool lendingPool = ILendingPool(leadingPoolAddress);

        erc20.transferFrom(msg.sender, address(this), _amount);
        lendingPool.deposit(_assetAddress, _amount, address(this), _referralCode);

        bytes32 uniqueKey = getPrivateUniqueKey(_assetAddress, msg.sender);

        lenders[uniqueKey].lenderAddress = msg.sender;
        lenders[uniqueKey].assetAddress = _assetAddress;
        lenders[uniqueKey].lendedAmount = lenders[uniqueKey].lendedAmount.add(_amount);
        lenders[uniqueKey].isLended = true;
        lenders[uniqueKey].amountType = EAmountType.Token;
        lenders[uniqueKey].lendedAt = getDateTimeNowInSeconds();

    }

    function withdrawlToken(address _assetAddress, uint256 _amount) external{
        if (!assets[_assetAddress]){
            revert("asset not allow");
        }

        if (_amount <= 0){
            revert("amount should be grater then 0");
        }

        ILendingPool lendingPool = ILendingPool(leadingPoolAddress);

        bytes32 uniqueKey = getPrivateUniqueKey(_assetAddress, msg.sender);

        if (!lenders[uniqueKey].isLended){
            revert("didn't lended any amount");
        }

        if (lenders[uniqueKey].lendedAmount < _amount){
            revert("amount to big");
        }

        lendingPool.withdraw(_assetAddress, _amount, lenders[uniqueKey].lenderAddress);

        lenders[uniqueKey].lendedAmount = lenders[uniqueKey].lendedAmount.sub(_amount);

    }

    function setAsset(address _assetAddress, bool _assetValue) external onlyOwner returns (address, bool){
        assets[_assetAddress] = _assetValue;

        return (_assetAddress, _assetValue);
    }

    function setVariableDebtBearingAddress(address _assetAddress, address _variableDebtBearingAddress) external onlyOwner returns (address, address){
        variableDebtBearings[_assetAddress] = _variableDebtBearingAddress;

        return (_assetAddress, _variableDebtBearingAddress);
    }

    function setAssetStableDebtBearingAddress(address _assetAddress, address _stableDebtBearingAddress) external onlyOwner returns (address, address){
        stableDebtBearings[_assetAddress] = _stableDebtBearingAddress;

        return (_assetAddress, _stableDebtBearingAddress);
    }

    function setInterestBearingAddress(address _assetAddress, address _interestBearingAddress) external onlyOwner returns (address, address){
        interestBearings[_assetAddress] = _interestBearingAddress;

        return (_assetAddress, _interestBearingAddress);
    }

    function setFeePercentage(uint256 _feePercentage) external onlyOwner returns (uint256){
        feePercentage = _feePercentage;

        return feePercentage;
    }

    function setLeadingPoolAddress(address _leadingPoolAddress) external onlyOwner returns (address){
        leadingPoolAddress = _leadingPoolAddress;

        return leadingPoolAddress;
    }

    //Common functions

    function getDateTimeNowInSeconds() private view returns (uint256){
        return block.timestamp;
    }

    //Contract unique key
    function getPrivateUniqueKey(address _contractAddress, address _userAddress) private pure returns (bytes32){
        return keccak256(abi.encodePacked(_contractAddress, _userAddress));
    }

    //Contract unique key
    function getPrivateUniqueKey(address _userAddress) private pure returns (bytes32){
        return keccak256(abi.encodePacked(_userAddress));
    }
}