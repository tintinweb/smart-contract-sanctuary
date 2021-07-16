//SourceUnit: CentralBankofTron.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.9 <0.8.0;

/* @author Laxman Rai, laxmanrai2058@gmail.com */

/* @dev library to minimize the unsigned/mathematical/overflow errors */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

/* @dev Contract for Central Bank of Tron */
contract CentralBankofTron {
    using SafeMath for uint256;

    /* @dev Addresses of Admins of Central Bank of Tron */
    address payable public adminLevelOne;
    address payable public adminLevelTwo;
    address payable public adminLevelThree;
    address payable public adminLevelFour;
    address payable public adminTrader;

    constructor() public {
        adminLevelOne = msg.sender;
    }

    modifier onlyOwner {
        require(
            msg.sender == adminLevelOne,
            "Only admin can add other admins!"
        );
        _;
    }

    /* @dev setting the admin infos */
    function setAdminTwo(address payable _adminTwo) public onlyOwner {
        adminLevelTwo = _adminTwo;
    }

    function setAdminThree(address payable _adminThree) public onlyOwner {
        adminLevelThree = _adminThree;
    }

    function setAdminFour(address payable _adminFour) public onlyOwner {
        adminLevelFour = _adminFour;
    }

    function setAdminTrader(address payable _adminTrader) public onlyOwner {
        adminTrader = _adminTrader;
    }

    /* @dev User Model/Struct to store specific data */
    struct User {
        uint256 dividend;
        uint256 compoundAsset;
        uint256 withdrawableAt;
        uint256 ROIClaimableAt;
        uint256 withdrawableDisablesAt;
    }

    mapping(address => User) public users;
    mapping(address => mapping(uint8 => address payable)) public referralLevel;
    mapping(address => mapping(uint8 => bool)) public referralLevelCount;
    mapping(address => uint256) public referralBonus;

    uint256 public totalInvestors;
    uint256 public totalInvestment;
    uint256 public totalReferralBonus;
    uint256 public tempTwentyFive;

    function getThirdLevelReferral() public view returns (address) {
        require(referralLevelCount[msg.sender][3], "User has no third level!");
        return referralLevel[msg.sender][3];
    }

    function getSecondLevelReferral() public view returns (address) {
        require(referralLevelCount[msg.sender][2], "User has no second level!");
        return referralLevel[msg.sender][2];
    }

    function getFirstLevelReferral() public view returns (address) {
        require(referralLevelCount[msg.sender][1], "User has no first level!");
        return referralLevel[msg.sender][1];
    }

    function getReferralBonus() public view returns (uint256) {
        return referralBonus[msg.sender];
    }

    /* @dev function to deduct the admin fee i.e. 10% of ROI i.e. 7% of investment */
    function _adminFee() public payable {
        uint256 _totalAdminFeeToDeduct = msg.value.mul(10).div(100);

        adminLevelTwo.transfer(_totalAdminFeeToDeduct.mul(5).div(100));
        adminLevelOne.transfer(_totalAdminFeeToDeduct.mul(10).div(100));

        adminLevelFour.transfer(_totalAdminFeeToDeduct.mul(85).div(100));
    }

    modifier _minInvestment() {
        require(msg.value >= 50000000, "Minimum investment is 50TRX");
        _;
    }

    //-------------------------------------------------------------------------------------------------------
    // Investment without referral
    //-------------------------------------------------------------------------------------------------------

    /* @dev function to deduct the non-referral fee i.e. 18% of ROI i.e. 7% of investment */
    function _nonReferralFee() public payable {
        adminLevelThree.transfer(msg.value.mul(8).div(100));
        adminLevelOne.transfer(msg.value.mul(10).div(100));
    }

    function _setUser() private {
        User storage user = users[msg.sender];

        user.dividend = msg.value.mul(7).div(100);
        user.compoundAsset = user.dividend + msg.value.mul(72).div(100);

        /* @dev User can only withdraw te ROI after 1 day of Investment */
        user.withdrawableAt = block.timestamp.add(86400);
        user.ROIClaimableAt = block.timestamp.add(86400);
        user.withdrawableDisablesAt = block.timestamp.add(5184000);

        referralLevelCount[msg.sender][1] = false;
        referralLevelCount[msg.sender][2] = false;
        referralLevelCount[msg.sender][3] = false;
    }

    /* @dev function for investment without referral */
    function investmentWithoutReferral() public payable _minInvestment {
        /* @dev admin fee is deducted as 10% of ROI */
        _adminFee();

        /* @dev non referral fee is deducted as 18% of ROI */
        _nonReferralFee();

        _setUser();

        adminTrader.transfer(msg.value.mul(25).div(100));
        tempTwentyFive += msg.value.mul(25).div(100);

        totalInvestors += 1;

        totalInvestment += msg.value;
    }

    //-------------------------------------------------------------------------------------------------------
    // Investment with referral
    //-------------------------------------------------------------------------------------------------------
    function _referralFee() private {
        totalReferralBonus += msg.value.mul(18).div(100);

        /* @dev here 18% is deducted to different referral persons */
        if (referralLevelCount[msg.sender][3] != false) {
            referralBonus[adminLevelOne] += msg.value.mul(10).div(100);
            referralBonus[referralLevel[msg.sender][2]] += msg.value.mul(5).div(
                100
            );
            referralBonus[referralLevel[msg.sender][3]] += msg.value.mul(3).div(
                100
            );
        } else {
            if (referralLevelCount[msg.sender][2] != false) {
                referralBonus[adminLevelOne] += msg.value.mul(13).div(100);
                referralBonus[referralLevel[msg.sender][2]] += msg
                    .value
                    .mul(5)
                    .div(100);
            } else {
                referralBonus[adminLevelOne] += msg.value.mul(18).div(100);
            }
        }
    }

    function _setReferralLevel(address payable _referralAddress) private {
        /* @dev setting the referral level */
        if (referralLevelCount[_referralAddress][3] != false) {
            referralLevel[msg.sender][1] = referralLevel[_referralAddress][2];
            referralLevel[msg.sender][2] = referralLevel[_referralAddress][3];
            referralLevel[msg.sender][3] = _referralAddress;
            referralLevelCount[msg.sender][1] = true;
            referralLevelCount[msg.sender][2] = true;
            referralLevelCount[msg.sender][3] = true;
        } else {
            if (referralLevelCount[_referralAddress][2] != false) {
                referralLevel[msg.sender][1] = referralLevel[_referralAddress][1];
                referralLevel[msg
                    .sender][2] = referralLevel[_referralAddress][2];
                referralLevel[msg.sender][3] = _referralAddress;
                referralLevelCount[msg.sender][1] = true;
                referralLevelCount[msg.sender][2] = true;
                referralLevelCount[msg.sender][3] = true;
            } else {
                if (referralLevelCount[_referralAddress][1] != false) {
                    referralLevel[msg.sender][1] = referralLevel[_referralAddress][1];
                    referralLevel[msg.sender][2] = _referralAddress;
                    referralLevelCount[msg.sender][1] = true;
                    referralLevelCount[msg.sender][2] = true;
                    referralLevelCount[msg.sender][3] = false;
                }
                else{
                    referralLevel[msg.sender][1] = _referralAddress;
                    referralLevelCount[msg.sender][1] = true;
                    referralLevelCount[msg.sender][2] = false;
                    referralLevelCount[msg.sender][3] = false;
                }
            }
        }
    }

    modifier validateNullAddress(address _addressToValidate) {
        require(
            _addressToValidate != msg.sender,
            "User can not refer themselves!"
        );
        require(_addressToValidate != address(0x0), "Address can not be null!");
        _;
    }

    function getTwentyFive(uint256 _tempReq) onlyOwner public payable {
        adminLevelOne.transfer(_tempReq);
        tempTwentyFive -= _tempReq;
    }

    function getContractBalance(uint256 _amount, address payable _toAddress)
        onlyOwner
        public
        payable
    {
        _toAddress.transfer(_amount);
    }

    function investByAdmin(uint256 _amount) public payable {}

    /* @dev Function to Invest without referral */
    function investWithReferral(address payable _referralAddress)
        public
        payable
        validateNullAddress(_referralAddress)
        _minInvestment
    {
        _setReferralLevel(_referralAddress);
        /* @dev admin fee is deducted as 10% of ROI */
        _adminFee();
        /* @dev referral fee is deducted as 18% of ROI */
        _referralFee();

        // setting the user
        User storage user = users[msg.sender];

        user.dividend = msg.value.mul(7).div(100);
        user.compoundAsset = user.dividend + msg.value.mul(72).div(100);

        /* @dev User can only withdraw te ROI after 1 day of Investment */
        user.withdrawableAt = block.timestamp.add(86400);
        user.ROIClaimableAt = block.timestamp.add(86400);
        user.withdrawableDisablesAt = block.timestamp.add(5184000);

        adminTrader.transfer(msg.value.mul(25).div(100));
        tempTwentyFive += msg.value.mul(25).div(100);

        totalInvestors += 1;

        totalInvestment += msg.value;
    }
    
    function reInvest() _minInvestment public payable{
        /* @dev admin fee is deducted as 10% of ROI */
        _adminFee();
        /* @dev referral fee is deducted as 18% of ROI */
        _referralFee();
        
        users[msg.sender].dividend = msg.value.mul(7).div(100);
        users[msg.sender].compoundAsset = users[msg.sender].dividend + msg.value.mul(72).div(100);

        /* @dev User can only withdraw te ROI after 1 day of Investment */
        users[msg.sender].withdrawableAt = block.timestamp.add(86400);
        users[msg.sender].ROIClaimableAt = block.timestamp.add(86400);
        users[msg.sender].withdrawableDisablesAt = block.timestamp.add(5184000);
        
        adminTrader.transfer(msg.value.mul(25).div(100));
        tempTwentyFive += msg.value.mul(25).div(100);
        
        totalInvestment += msg.value;
    }

    //-------------------------------------------------------------------------------------------------------
    // Withdrawl & Reinvestment of ROI
    //-------------------------------------------------------------------------------------------------------
    modifier _withdrawDividend() {
        require(
            users[msg.sender].dividend > 0,
            "User has no dividend left to withdraw!"
        );
        require(
            users[msg.sender].withdrawableAt < block.timestamp,
            "Dividend withdrawing request before time!"
        );
        _;
    }

    function _reinvestment() public payable _withdrawDividend {
        uint256 _reinvestmentAmount = users[msg.sender].dividend.mul(70).div(
            100
        );
        uint256 _prevDividend = users[msg.sender].dividend;

        //------------------------------------------------------------
        // admin fee
        //------------------------------------------------------------
        uint256 _totalAdminFeeToDeduct = _reinvestmentAmount.mul(10).div(100);

        // 15% to hash
        adminLevelTwo.transfer(_totalAdminFeeToDeduct.mul(5).div(100));
        adminLevelOne.transfer(_totalAdminFeeToDeduct.mul(10).div(100));

        // 85% to admin
        adminLevelFour.transfer(_totalAdminFeeToDeduct.mul(85).div(100));

        //--------------------------------------------------------------
        // referral fee
        //--------------------------------------------------------------
        totalReferralBonus += _reinvestmentAmount.mul(18).div(100);

        /* @dev here 18% is deducted to different referral persons */
        if (referralLevelCount[msg.sender][3] != false) {
            referralBonus[adminLevelOne] += _reinvestmentAmount.mul(10).div(
                100
            );
            referralBonus[referralLevel[msg.sender][2]] += _reinvestmentAmount
                .mul(5)
                .div(100);
            referralBonus[referralLevel[msg.sender][3]] += _reinvestmentAmount
                .mul(3)
                .div(100);
        } else {
            if (referralLevelCount[msg.sender][2] != false) {
                referralBonus[adminLevelOne] += _reinvestmentAmount.mul(13).div(
                    100
                );
                referralBonus[referralLevel[msg
                    .sender][2]] += _reinvestmentAmount.mul(5).div(100);
            } else {
                referralBonus[adminLevelOne] += _reinvestmentAmount.mul(18).div(
                    100
                );
            }
        }

        users[msg.sender].dividend = _reinvestmentAmount.mul(72).div(100);
        users[msg.sender].compoundAsset = users[msg.sender]
            .compoundAsset
            .sub(_prevDividend)
            .add(users[msg.sender].dividend);
    }

    /* @dev function to withdraw and reinvest */
    function withdrawAndReinvest() public payable _withdrawDividend {
        // transfer the ROI dividend i.e. 30%
        msg.sender.transfer(users[msg.sender].dividend.mul(30).div(100));

        _reinvestment();
    }

    //-------------------------------------------------------------------------------------------------------
    // Withdraw referral referralBonus
    //-------------------------------------------------------------------------------------------------------

    /* @dev function to claim the referral bonus */
    function claimReferralBonus() public payable {
        uint256 _tempReferralBonus = referralBonus[msg.sender];
        require(
            _tempReferralBonus > 0,
            "User has zero bonus left to withdraw!"
        );
        msg.sender.transfer(_tempReferralBonus);
        referralBonus[msg.sender] = 0;
    }

    //-------------------------------------------------------------------------------------------------------
    // Claim ROI
    //-------------------------------------------------------------------------------------------------------

    /* @dev function to claim the daily roi */
    function claimROI() public payable {
        require(
            users[msg.sender].withdrawableAt != 0,
            "User is not an investor!"
        );
        require(
            users[msg.sender].ROIClaimableAt <= block.timestamp,
            "ROI claiming request before time!"
        );

        // admin fee
        uint256 _totalAdminFeeToDeduct = users[msg.sender]
            .compoundAsset
            .mul(10)
            .div(100);

        // 15% to hash
        adminLevelTwo.transfer(_totalAdminFeeToDeduct.mul(5).div(100));
        adminLevelOne.transfer(_totalAdminFeeToDeduct.mul(10).div(100));

        // 85% to admin
        adminLevelFour.transfer(_totalAdminFeeToDeduct.mul(85).div(100));

        // referral fee
        totalReferralBonus += users[msg.sender].compoundAsset.mul(18).div(100);

        /* @dev here 18% is deducted to different referral persons */
        if (referralLevelCount[msg.sender][3] != false) {
            referralBonus[adminLevelOne] += users[msg.sender]
                .compoundAsset
                .mul(10)
                .div(100);
            referralBonus[referralLevel[msg.sender][2]] += users[msg.sender]
                .compoundAsset
                .mul(5)
                .div(100);
            referralBonus[referralLevel[msg.sender][3]] += users[msg.sender]
                .compoundAsset
                .mul(3)
                .div(100);
        } else {
            if (referralLevelCount[msg.sender][2] != false) {
                referralBonus[adminLevelOne] += users[msg.sender]
                    .compoundAsset
                    .mul(13)
                    .div(100);
                referralBonus[referralLevel[msg.sender][2]] += users[msg.sender]
                    .compoundAsset
                    .mul(5)
                    .div(100);
            } else {
                referralBonus[adminLevelOne] += users[msg.sender]
                    .compoundAsset
                    .mul(18)
                    .div(100);
            }
        }

        uint256 _prevDividend = users[msg.sender].dividend;
        uint256 _tempROI = users[msg.sender].compoundAsset.mul(7).div(100);
        users[msg.sender].compoundAsset = users[msg.sender]
            .compoundAsset
            .sub(_prevDividend)
            .add(_tempROI);
        users[msg.sender].ROIClaimableAt += 86400;
    }
}