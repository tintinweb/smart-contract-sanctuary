// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./ILendingPool.sol";
import "./IWETHGateway.sol";
import "./IStakingPool.sol";
import "./IProtocolDataProvider.sol";

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
        bool isexisted;
        bool isFirstCycle;
    }

    enum EAmountType{
        None,
        Coin,
        Token
    }

    uint256 public feePercentage;
    
    address private stakingPoolAddress;
    address public lendingPoolAddress;
    address private addressProvider;
    address public wETHGatewayAddress;
    address public protocolDataProvider;
    //IProtocolDataProvider dataProvider = IProtocolDataProvider(address(0x686c626E48bfC5DC98a30a9992897766fed4Abd3));

    mapping (address => bool) public assets;
    mapping (address => uint256) public depositsbyasset;// Recording total deposits per asset
    //mapping (address=> uint256) public currentcycleReward; // Records total rewards per asset per cycle 
    mapping (address => address) public variableDebtBearings;
    mapping (address => address) public stableDebtBearings;
    mapping (address => address) public interestBearings;

    mapping (bytes32 => Lender) public lenders;

    address[] public totalLenders;


    //constructor(address _leadingPoolAddress, address _wETHGatewayAddress,address _stakingPool,uint256 _feePercentage){
    constructor(){
        lendingPoolAddress = 0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe;//_lendingPoolAddress;
        addressProvider = 0x88757f2f99175387aB4C6a4b3067c77A695b0349; // Using Address provider for lending pool address as recomended by aave. In case lending pool address changes
        wETHGatewayAddress = 0xA61ca04DF33B72b235a8A28CfB535bb7A5271B70;//_wETHGatewayAddress;
        feePercentage = 10;//_feePercentage;
        stakingPoolAddress=0x4da27a545c0c5B758a6BA100e3a049001de870f5;//_stakingPool;
        protocolDataProvider= 0x3c73A5E5785cAC854D468F727c606C07488a29D6;
    }

    function getTokenLender(address _assetAddress, address _lenderAddress) public view returns(Lender memory){
        bytes32 uniqueKey = getPrivateUniqueKey(_assetAddress, _lenderAddress);

        return lenders[uniqueKey];
    }

    function getCoinLender(address _lenderAddress) public view returns(Lender memory){
        bytes32 uniqueKey = getPrivateUniqueKey(_lenderAddress);

        return lenders[uniqueKey];
    }

    function depositAsset(address _assetAddress, uint256 _amount, uint16 _referralCode) external payable{
       /* if (!assets[_assetAddress]){
            revert("asset not allow");
        }

        if (_amount <= 0){
            revert("amount should be grater then 0");
        }*/
        
        IERC20 erc20 = IERC20(_assetAddress);
        erc20.transferFrom(msg.sender, address(this), _amount);
       // ILendingPoolAddressesProvider addressprovider = ILendingPoolAddressesProvider()
        //ILendingPoolAddressesProvider lendingaddressProvider = ILendingPoolAddressesProvider(addressProvider);
        //ILendingPool lendingPool = ILendingPool(lendingaddressProvider.getLendingPool());
        ILendingPool lendingPool = ILendingPool(lendingPoolAddress);

        //erc20.transferFrom(msg.sender, address(this), _amount);
        IERC20(_assetAddress).approve(address(lendingPool), _amount);
        lendingPool.deposit(_assetAddress, _amount, address(this), _referralCode);// we are sending contract address in To field of deposit. so it will send a tokens to contract
       // stakeTokens();
        bytes32 uniqueKey = getPrivateUniqueKey(_assetAddress, msg.sender);
        if(lenders[uniqueKey].isexisted!=true)
        {
            totalLenders.push(msg.sender);
        }
        lenders[uniqueKey].lenderAddress = msg.sender;
        lenders[uniqueKey].assetAddress = _assetAddress;
        lenders[uniqueKey].lendedAmount = lenders[uniqueKey].lendedAmount.add(_amount);
        lenders[uniqueKey].isLended = true;
        lenders[uniqueKey].amountType = EAmountType.Token;
        lenders[uniqueKey].lendedAt = getDateTimeNowInSeconds();
        lenders[uniqueKey].isexisted=true;
        lenders[uniqueKey].isFirstCycle=true;
        depositsbyasset[_assetAddress]= depositsbyasset[_assetAddress].add(_amount);

    }

    function stakeTokens() private 
    {
        IStakingPool stakingpool = IStakingPool(stakingPoolAddress);
        uint256 contractBalance = address(this).balance;
        stakingpool.stake(address(this),contractBalance);
    }

    function withdrawlAsset(address _assetAddress, uint256 _amount) external{
        if (!assets[_assetAddress]){
            revert("asset not allow");
        }

        if (_amount <= 0){
            revert("amount should be grater then 0");
        }

        ILendingPool lendingPool = ILendingPool(lendingPoolAddress);

        bytes32 uniqueKey = getPrivateUniqueKey(_assetAddress, msg.sender);

        if (!lenders[uniqueKey].isLended){
            revert("didn't lended any amount");
        }

        if (lenders[uniqueKey].lendedAmount < _amount){
            revert("amount to big");
        }

        lendingPool.withdraw(_assetAddress, _amount, lenders[uniqueKey].lenderAddress);

        lenders[uniqueKey].lendedAmount = lenders[uniqueKey].lendedAmount.sub(_amount);

        depositsbyasset[_assetAddress]=depositsbyasset[_assetAddress].sub(_amount);

    }


    /*function calculateReward(address _assetAddress) private view returns (uint256)
    {
        uint256 totalDeposit = depositsbyasset[_assetAddress];
        uint256 totalreward = (totalDeposit.mul(10)).div(100);

        return totalreward;
    }*/

    function claimRewards(address _assetAddress)external payable
    {
         if (!assets[_assetAddress]){
            revert("asset not allowed");
        }

        IERC20 erc20 = IERC20(_assetAddress);
        //IStakingPool stakingpool = IStakingPool(stakingPoolAddress);
        IProtocolDataProvider dataProvider = IProtocolDataProvider(protocolDataProvider);
        //stakingpool.claimRewards(address(this),type(uint).max);
        (address aTokenAddress,,) = dataProvider.getReserveTokensAddresses(_assetAddress);
        uint256 contractBalance = IERC20(aTokenAddress).balanceOf( address(this));//.balance;
        contractBalance= contractBalance.sub(depositsbyasset[_assetAddress]);
        uint comission = (contractBalance.mul(feePercentage)).div(100);
        contractBalance= contractBalance.sub(comission);
        uint256 totaldepositofAsset = depositsbyasset[_assetAddress];
        for(uint16 i = 0; i < totalLenders.length; i ++)
        {
            bytes32 uniqueKey = getPrivateUniqueKey(_assetAddress, totalLenders[i]);
            if(!lenders[uniqueKey].isFirstCycle)
            {
                uint256 investordepositforAsset= lenders[uniqueKey].lendedAmount;
                uint256 depositPercentage = (investordepositforAsset.mul(100)).div(totaldepositofAsset);
                uint256 lenderShare = (contractBalance.mul(depositPercentage)).div(100);
                address payable laddress = payable(lenders[uniqueKey].lenderAddress);
                erc20.transfer(laddress,lenderShare);
            }else{
                lenders[uniqueKey].isFirstCycle = false;
            }
        }
        erc20.transfer(owner(),comission);
       
       // laddress.transfer(contractBalance);
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

    function setLeadingPoolAddress(address _lendingPoolAddress) external onlyOwner returns (address){
        lendingPoolAddress = _lendingPoolAddress;

        return lendingPoolAddress;
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