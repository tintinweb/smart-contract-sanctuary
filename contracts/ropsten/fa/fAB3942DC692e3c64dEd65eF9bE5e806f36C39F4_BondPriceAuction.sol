// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

contract BondPriceAuction {

    /**
     * @dev Reverts if bidding time is not open
     */
    modifier onlyWhileBiddingOpen {
        require(isOpen(), "Bidding time is closed");
        _;
    }

    /**
     * @dev Reverts if bidding time is still open
     */
    modifier onlyWhenBiddingClosed {
        require(!isOpen(), "Bidding time is still open");
        _;
    }

    event Bid(address bidder, uint256 coupon, uint256 amount);
    event CouponSet(uint256 coupon);
    event DemandNotMet(uint256 totalDemand, uint256 expectedDemand);

    address private _owner;
    string private _project;
    address private _company;
    uint256 private _minCoupon;
    uint256 private _maxCoupon;
    uint256 private _coupon;
    uint256 private _seekedNumberOfBonds;
    uint256 private _bidClosingTime;

    uint256[] private _couponMatrix;

    constructor(
        string memory project,
        address company,
        uint256 minCoupon,
        uint256 maxCoupon,
        uint256 seekedNumberOfBonds,
        uint256 bidClosingTime
    ) {
        require(bidClosingTime > block.timestamp, "Closing time can't be in the past");
        _project = project;
        _company = company;
        _minCoupon = minCoupon;
        _maxCoupon = maxCoupon;
        _seekedNumberOfBonds = seekedNumberOfBonds;
        _bidClosingTime = bidClosingTime;
        _owner = msg.sender;
        // Initialise coupon to 0
        _coupon = 0;

        // Initialize array to 0s
        for (uint i = 0; i < maxCoupon; i++) {
            _couponMatrix.push(0);
        }
    }

    function getProject() public view returns(string memory) {
        return _project;
    }

    function getCompany() public view returns(address) {
        return _company;
    }

    function getCoupon() public view returns(uint256) {
        return _coupon;
    }

    function getMinCoupon() public view returns(uint256){
        return _minCoupon;
    }

    function getMaxCoupon() public view returns(uint256){
        return _maxCoupon;
    }

    function getSeekedNumberOfBonds() public view returns(uint256) {
        return _seekedNumberOfBonds;
    }

    function getBidClosingTime() public view returns(uint256) {
        return _bidClosingTime;
    }

    function getDemandAtCouponLevel(uint256 coupon) public view returns(uint256) {
        require(coupon >= _minCoupon && coupon <= _maxCoupon, "Coupon out of range");
        return _couponMatrix[coupon - 1];
    }

    /**
     * @return true if the registering investments is open, false otherwise.
     */
    function isOpen() public view returns (bool) {
        return block.timestamp <= _bidClosingTime;
   }


    function registerBid(uint256 coupon, uint256 numberOfTokens) public onlyWhileBiddingOpen {
        require(coupon >= _minCoupon && coupon <= _maxCoupon, "Coupon needs to be between the set range");

        // Update the coupon record
        uint256 index = coupon - 1;
        uint256 currentDemand = _couponMatrix[index];
        _couponMatrix[index] = currentDemand + numberOfTokens;
        emit Bid(msg.sender, coupon, numberOfTokens);
    }

    function defineCoupon() public onlyWhenBiddingClosed {
        require(msg.sender == _owner, "Only owner can define the coupon");
        // Variable for the total demand for tokens
        uint256 tokenDemand = 0;

        // Iterate each coupon level, and count the token demand to
        // determine the coupon level which will fulfill the seeked number of tokens
        for(uint i = _maxCoupon; i > 0 ; i--) {
            // Increase the token 
            tokenDemand += _couponMatrix[i-1];
            // If enough interest at this copupn level, set coupon and break the loop
            if (tokenDemand >= _seekedNumberOfBonds) {
                _coupon = i;
                break;
            }
        }
        if (_coupon > 0) {
            emit CouponSet(_coupon);
        } else {
            emit DemandNotMet(tokenDemand, _seekedNumberOfBonds);
        }
        
    }
}

