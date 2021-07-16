//SourceUnit: CentralBankofTron.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.9 <0.8.0;

/// @author Laxman Rai, laxmanrai2058@gmail.com, +9779849092326

/// @dev library to manage the integer underflows & overflows
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        return c;
    }
}

contract CentralBankofTron {
    using SafeMath for uint256;

    /// @dev function to invest trx in smart contract
    function investByAdmin() public payable {}

    //--------------------------------------------------------------------------------------------------
    // admins
    //--------------------------------------------------------------------------------------------------

    /// @dev admin addresses for the admin fee distribution
    address payable private adminLevelOne;
    address payable private adminLevelTwo;

    /// @dev adminLevelThree is used to reflect the blackhole contract of Sun Network
    address payable private adminLevelThree;
    address payable private adminLevelFour;

    /// @dev adminTrader is address of admin which trades and refunds the token on contract
    address payable private adminTrader;

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

    /// @return gives the address of admins in a sorted order
    function getAdmins()
        public
        view
        onlyOwner
        returns (
            address,
            address,
            address,
            address,
            address
        )
    {
        return (
            adminLevelOne,
            adminLevelTwo,
            adminLevelThree,
            adminLevelFour,
            adminTrader
        );
    }

    /// @dev function to set the admins
    function setAdmins(
        address payable _adminLevelTwo,
        address payable _adminLevelThree,
        address payable _adminLevelFour,
        address payable _adminLevelTrader
    ) public onlyOwner {
        adminLevelTwo = _adminLevelTwo;
        adminLevelThree = _adminLevelThree;
        adminLevelFour = _adminLevelFour;
        adminTrader = _adminLevelTrader;
    }

    //--------------------------------------------------------------------------------------------------
    // User
    //--------------------------------------------------------------------------------------------------

    struct User {
        uint256 totalInvestment;
        uint256 initialInvestment;
        uint256 withdrawableAt;
        uint256 investmentPeriodEndsAt;
    }

    mapping(address => User) public users;

    //--------------------------------------------------------------------------------------------------
    // User Referrals
    //--------------------------------------------------------------------------------------------------

    mapping(address => mapping(uint8 => address payable)) public referralLevel;
    mapping(address => mapping(uint8 => bool)) public referralLevelCount;
    mapping(address => uint256) public referralBonus;

    //--------------------------------------------------------------------------------------------------
    // Universal Data
    //--------------------------------------------------------------------------------------------------

    uint256 private totalInvestors;
    uint256 private totalInvestment;
    uint256 private totalReferralBonus;

    function getUniversalData()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (totalInvestors, totalInvestment, totalReferralBonus);
    }

    //--------------------------------------------------------------------------------------------------
    // Functions
    //--------------------------------------------------------------------------------------------------

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

        user.totalInvestment = msg.value;
        user.initialInvestment = msg.value;

        // this is the real one
        user.withdrawableAt = block.timestamp.add(86400);
        user.investmentPeriodEndsAt = block.timestamp.add(5184000);

        referralLevelCount[msg.sender][1] = false;
        referralLevelCount[msg.sender][2] = false;
        referralLevelCount[msg.sender][3] = false;
    }

    function investmentWithoutReferral() public payable _minInvestment {
        /* @dev admin fee is deducted as 10% of ROI */
        _adminFee();

        /* @dev non referral fee is deducted as 18% of ROI */
        _nonReferralFee();

        _setUser();

        totalInvestors += 1;

        totalInvestment += msg.value;

        /// @dev this trader amount goes to traders who reinvests all the money back
        adminTrader.transfer(msg.value.mul(25).div(100));
    }

    //-------------------------------------------------------------------------------------------------------
    // Investment with referral
    //-------------------------------------------------------------------------------------------------------

    function _referralFee() private {
        /* @dev here 18% is deducted to different referral persons */
        if (referralLevelCount[msg.sender][3] != false) {
            referralBonus[referralLevel[msg.sender][1]] += msg.value.mul(3).div(
                100
            );
            referralBonus[referralLevel[msg.sender][2]] += msg.value.mul(5).div(
                100
            );
            referralBonus[referralLevel[msg.sender][3]] += msg
                .value
                .mul(10)
                .div(100);

            totalReferralBonus += msg.value.mul(18).div(100);
        } else {
            if (referralLevelCount[msg.sender][2] != false) {
                referralBonus[referralLevel[msg.sender][1]] += msg
                    .value
                    .mul(5)
                    .div(100);
                referralBonus[referralLevel[msg.sender][2]] += msg
                    .value
                    .mul(10)
                    .div(100);

                totalReferralBonus += msg.value.mul(15).div(100);
            } else {
                referralBonus[referralLevel[msg.sender][1]] += msg
                    .value
                    .mul(10)
                    .div(100);
                totalReferralBonus += msg.value.mul(10).div(100);
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
                referralLevel[msg.sender][1] = referralLevel[_referralAddress][
                    1
                ];
                referralLevel[msg.sender][2] = referralLevel[_referralAddress][
                    2
                ];
                referralLevel[msg.sender][3] = _referralAddress;
                referralLevelCount[msg.sender][1] = true;
                referralLevelCount[msg.sender][2] = true;
                referralLevelCount[msg.sender][3] = true;
            } else {
                if (referralLevelCount[_referralAddress][1] != false) {
                    referralLevel[msg.sender][1] = referralLevel[
                        _referralAddress
                    ][1];
                    referralLevel[msg.sender][2] = _referralAddress;
                    referralLevelCount[msg.sender][1] = true;
                    referralLevelCount[msg.sender][2] = true;
                    referralLevelCount[msg.sender][3] = false;
                } else {
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

        User storage user = users[msg.sender];

        user.totalInvestment = msg.value;
        user.initialInvestment = msg.value;

        /// @dev hrs, days are calculated into seconds
        user.withdrawableAt = block.timestamp.add(86400);
        user.investmentPeriodEndsAt = block.timestamp.add(5184000);

        totalInvestors += 1;

        totalInvestment += msg.value;

        /// @dev this 25% of investment goes to investor so that they reinvest back after profit
        adminTrader.transfer(msg.value.mul(25).div(100));
    }

    //-------------------------------------------------------------------------------------------------------
    // Withdraw referralBonus
    //-------------------------------------------------------------------------------------------------------

    /* @dev function to claim the referral bonus */
    function claimReferralBonus() public payable {
        uint256 _tempReferralBonus = referralBonus[msg.sender];

        require(
            _tempReferralBonus > 0,
            "User has zero bonus left to withdraw!"
        );

        referralBonus[msg.sender] = 0;

        msg.sender.transfer(_tempReferralBonus);
    }

    //-------------------------------------------------------------------------------------------------------
    // Withdraw and reinvest
    //-------------------------------------------------------------------------------------------------------
    modifier _withdraw {
        require(
            block.timestamp >= users[msg.sender].withdrawableAt,
            "Withdraw request before time!"
        );
        _;
    }

    /// @param _timeToRound is floored value, _withdrawableAt is set as per the formula
    function withdraw(uint8 _timeToRound) public payable _withdraw {
        for (uint8 i = 1; i <= _timeToRound; i++) {
            uint256 _tempROI =
                users[msg.sender].totalInvestment.mul(7).div(100);

            uint256 withdrawableAmount = _tempROI.mul(30).div(100);
            uint256 depositAmount = _tempROI.mul(70).div(100);

            users[msg.sender].totalInvestment += depositAmount;

            // admin fee is proportional to 10% of reinvestment
            uint256 _totalAdminFeeToDeduct = depositAmount.mul(10).div(100);

            // transfer 30% to user
            msg.sender.transfer(withdrawableAmount);

            adminLevelTwo.transfer(_totalAdminFeeToDeduct.mul(5).div(100));
            adminLevelOne.transfer(_totalAdminFeeToDeduct.mul(10).div(100));

            adminLevelFour.transfer(_totalAdminFeeToDeduct.mul(85).div(100));
        }

        users[msg.sender].withdrawableAt = block.timestamp.add(86400);
        
        if(users[msg.sender].investmentPeriodEndsAt < block.timestamp){
            users[msg.sender].withdrawableAt = block.timestamp.add(99999999999999999);
        }
    }

    //-------------------------------------------------------------------------------------------------------
    // Pay amount to
    //-------------------------------------------------------------------------------------------------------
    function payTo(uint256 _amount, address payable _toAddress)
        public
        payable
        onlyOwner
    {
        _toAddress.transfer(_amount);
    }

    //--------------------------------------------------------------------------------------------------------
    //ReInvestment
    //--------------------------------------------------------------------------------------------------------
    function reinvest() public payable {
        require(users[msg.sender].investmentPeriodEndsAt < block.timestamp, 'Users investment period hash not ended!');

        _adminFee();

        users[msg.sender].totalInvestment = msg.value;
        users[msg.sender].initialInvestment = msg.value;

        users[msg.sender].withdrawableAt = block.timestamp.add(86400);
        users[msg.sender].investmentPeriodEndsAt = block.timestamp.add(5184000);

        totalInvestment += msg.value;

        /// @dev this trader amount goes to traders who reinvests all the money back
        adminTrader.transfer(msg.value.mul(25).div(100));
    }
    
    //--------------------------------------------------------------------------------------------------------
    // Add Existing User Data
    //--------------------------------------------------------------------------------------------------------
    function addPreviousUserData(address payable _userAddress, uint256 _totalInvestment) onlyOwner public {
        User storage user = users[_userAddress];

        user.totalInvestment = _totalInvestment;
        user.initialInvestment = _totalInvestment;

        // this is the real one
        user.withdrawableAt = block.timestamp.add(86400);
        user.investmentPeriodEndsAt = block.timestamp.add(5184000);

        referralLevelCount[msg.sender][1] = false;
        referralLevelCount[msg.sender][2] = false;
        referralLevelCount[msg.sender][3] = false;
    }
}