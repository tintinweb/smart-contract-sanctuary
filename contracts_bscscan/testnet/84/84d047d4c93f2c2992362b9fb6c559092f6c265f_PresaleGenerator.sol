// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;


import "./Ownable.sol";
import "./SafeMath.sol";
import "./EnumerableSet.sol";
import "./Presale.sol";
import "./IPresaleFactory.sol";
import "./TransferHelper.sol";

contract PresaleGenerator is Ownable {
    using SafeMath for uint256;
    
    event FeesUpdated(uint256 creationFee, uint256 distributionFee);

    struct PresaleParams{
        uint256 presaleRate; 
        uint256 minSpendPerBuyer;
        uint256 maxSpendPerBuyer; 
        uint256 softcap; 
        uint256 hardcap; 
        uint256 liquidityPercent; 
        uint256 listingRate; 
        uint256 startBlock; //unix timestamp
        uint256 endBlock; //unix timestamp
        uint256 lockPeriod; //unix timestamp
    }

    IPresaleFactory public presaleFactory;
    ISmartLockForwarder public smartLockForwarder;
    address public baseTokenAddr;
    IVerify verifyAddress;
    uint256 public creationFee;
    uint256 public distributionFee;
    address public devAddr;
    IStaking public smartStaking; 
    bool private firstPresale;

    constructor(
        IPresaleFactory _presaleFactory, 
        ISmartLockForwarder _smartLockForwarder, 
        address _smartStakingAddr, 
        address _devAddr,
        IVerify _verifyAddress,
        address _baseTokenAddr) 
    public {
        presaleFactory = _presaleFactory;
        smartLockForwarder = _smartLockForwarder;
        smartStaking = IStaking(_smartStakingAddr);
        devAddr = _devAddr;
        verifyAddress = _verifyAddress;
        baseTokenAddr = _baseTokenAddr;
        firstPresale = true;
    }
    

    function updateFees(uint256 _totalFee) public onlyOwner{
        creationFee = _totalFee.mul(750).div(1000);
        distributionFee = _totalFee.sub(creationFee);

        emit FeesUpdated(creationFee, distributionFee);
    }

    function calculateAmountRequired (
        uint256 _hardcap, 
        uint256 _presaleRate, 
        uint256 _listingRate, 
        uint256 _liquidityPercent) 
    internal pure returns (uint256) {
        uint256 amount = _hardcap.mul(_presaleRate).div(uint256(10 ** 18));
        uint256 liquidityRequired = _hardcap.mul(_liquidityPercent).mul(_listingRate).div(10 ** 21);
        uint256 tokensRequiredForPresale = amount.add(liquidityRequired);
        return tokensRequiredForPresale;
    }
    
    function createPresale(
        address payable _presaleOwner,
        IERC20 _presaleToken,
        uint256[10] memory uint_params,
        bytes32 linksHash) public payable{
        //Presale Params
        PresaleParams memory params;
        params.presaleRate = uint_params[0]; 
        params.minSpendPerBuyer = uint_params[1];
        params.maxSpendPerBuyer = uint_params[2]; 
        params.softcap = uint_params[3]; 
        params.hardcap = uint_params[4]; 
        params.liquidityPercent = uint_params[5]; 
        params.listingRate = uint_params[6]; 
        params.startBlock = uint_params[7]; 
        params.endBlock = uint_params[8]; 
        params.lockPeriod = uint_params[9];
        
        require(msg.value == creationFee.add(distributionFee), 'Wrong balance!');
        require(params.hardcap.mul(params.presaleRate) >= 10000, 'Min divis');
        require(params.endBlock.sub(params.startBlock) <= 2 weeks, "Invalid start-end");
        require(params.presaleRate.mul(params.hardcap) > 0, 'Invalid params');
        require(params.listingRate > 0, 'Invalid params');
        require(params.liquidityPercent >= 500 && params.liquidityPercent <= 1000, 'liq > 50%');
        require(params.softcap < params.hardcap, "SC < HC");
        require(params.lockPeriod >= 4 weeks, "Invalid lock");     

        if(distributionFee != 0)
            smartStaking.distribute{value: distributionFee}();
        if(creationFee != 0)
            payable(devAddr).transfer(creationFee);
        if(!firstPresale){
            require(params.hardcap <= params.softcap.mul(2), 'Invalid params');
        }

        uint256 tokensForPresale = calculateAmountRequired(params.hardcap, params.presaleRate, params.listingRate, params.liquidityPercent);

        Presale newPresale = new Presale(address(this), smartLockForwarder, baseTokenAddr, payable(devAddr), smartStaking, verifyAddress);
        TransferHelper.safeTransferFrom(address(_presaleToken), address(msg.sender), address(newPresale), tokensForPresale);

        require(_presaleToken.balanceOf(address(newPresale)) == tokensForPresale, "Transfer from failed!");

        newPresale.initPresale1(
            params.presaleRate,
            params.minSpendPerBuyer, 
            params.maxSpendPerBuyer, 
            params.softcap, 
            params.hardcap, 
            params.liquidityPercent, 
            params.listingRate, 
            params.startBlock, 
            params.endBlock, 
            params.lockPeriod);
        
        uint256 presaleID = presaleFactory.presalesLength();
        newPresale.initPresale2(_presaleOwner, _presaleToken, baseTokenAddr, linksHash, presaleID);
        presaleFactory.registerPresale(address(newPresale));
        firstPresale = false;
    }

}