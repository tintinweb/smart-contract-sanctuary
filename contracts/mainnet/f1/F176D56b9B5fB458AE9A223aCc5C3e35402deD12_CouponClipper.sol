pragma solidity 0.7.4;
// SPDX-License-Identifier: MIT

interface IESDS {
    function redeemCoupons(uint256 epoch, uint256 couponAmount) external;
    function transferCoupons(address sender, address recipient, uint256 epoch, uint256 amount) external;
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

// @notice Lets anybody trustlessly redeem coupons on anyone else's behalf for a fee (default fee is 1%).
//    Requires that the coupon holder has previously approved this contract via the ESDS `approveCoupons` function.
// @dev Bots should scan for the `CouponApproval` event emitted by the ESDS `approveCoupons` function to find out which 
//    users have approved this contract to redeem their coupons.
contract CouponClipper {

    IERC20 constant private ESD = IERC20(0x36F3FD68E7325a35EB768F1AedaAe9EA0689d723);
    IESDS constant private ESDS = IESDS(0x443D2f2755DB5942601fa062Cc248aAA153313D3);

    // The percent fee offered by coupon holders to callers (bots), in basis points
    // E.g., offers[_user] = 500 indicates that _user will pay 500 basis points (5%) to the caller
    mapping(address => uint256) private offers;

    // @notice Gets the number of basis points the _user is offering the bots
    // @dev The default value is 100 basis points (1%).
    //   That is, `offers[_user] = 0` is interpretted as 1%.
    //   This way users who are comfortable with the default 1% offer don't have to make any additional contract calls.
    // @param _user The account whose offer we're looking up.
    // @return The number of basis points the account is offering the callers (bots)
    function getOffer(address _user) public view returns (uint256) {
        uint256 offer = offers[_user];
        return offer == 0 ? 100 : offer;
    }

    // @notice Allows msg.sender to change the number of basis points they are offering.
    // @dev An _offer value of 0 will be interpretted as the "default offer", which is 100 basis points (1%).
    // @param _offer The number of basis points msg.sender wants to offer the callers (bots).
    function setOffer(uint256 _offer) external {
        require(_offer <= 10_000, "Offer exceeds 100%.");
        offers[msg.sender] = _offer;
    }

    // @notice Allows anyone to redeem coupons for ESD on the coupon-holder's bahalf
    // @param _user Address of the user holding the coupons (and who has approved this contract)
    // @param _epoch The epoch in which the _user purchased the coupons
    // @param _couponAmount The number of coupons to redeem (18 decimals)
    function redeem(address _user, uint256 _epoch, uint256 _couponAmount) external {
        
        // pull user's coupons into this contract (requires that the user has approved this contract)
        ESDS.transferCoupons(_user, address(this), _epoch, _couponAmount);
        
        // redeem the coupons for ESD
        ESDS.redeemCoupons(_epoch, _couponAmount);
        
        // pay the caller their fee
        uint256 botFee = _couponAmount * getOffer(_user) / 10_000;
        ESD.transfer(msg.sender, botFee); // @audit-ok : reverts on failure
        
        // send the ESD to the user
        ESD.transfer(_user, _couponAmount - botFee); // @audit-ok : no underflow and reverts on failure
    }
}