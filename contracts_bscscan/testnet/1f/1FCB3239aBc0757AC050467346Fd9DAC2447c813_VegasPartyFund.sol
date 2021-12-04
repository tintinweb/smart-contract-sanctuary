// SPDX-License-Identifier: U-U-U-UPPPPP!!!
pragma solidity 0.7.4;

import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract VegasPartyFund {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public admin;
    address payable public partyLord;

    uint256 public lastPartyTimeCall;

    IERC20 token;

    event onPushPayment(address indexed _recipient, uint256 _amount1, uint256 _amount2, uint256 _timestamp);

    modifier onceAYearOnly() {
        require((block.timestamp).sub(lastPartyTimeCall) >= 365 days, "NOT_PARTY_TIME_YET");
        _;
    }

    constructor(address _token, address payable _partyLord) {
        token = IERC20(_token);
        partyLord = _partyLord;
    }

    receive() external payable {

    }

    // Funds for travel to the VGP
    function forTravel() public view returns (uint256 _balance) {
        return (token.balanceOf(address(this)).mul(2000) / 10000);
    }

    // Funds for the VGP
    function forParty() public view returns (uint256 _balance) {
        return token.balanceOf(address(this)).sub(forTravel());
    }

    // Let's get this party started, RIIIIIIGHT?
    function partyTime() external onceAYearOnly() returns (bool _success) {
        
        // Get the payout values to transfer
        uint256 _payout1 = forTravel();
        uint256 _payout2 = forParty();

        // Send the tokens to the Party Lord
        token.transfer(partyLord, _payout1);
        token.transfer(partyLord, _payout2);

        // Transfer any base to the Party Lord
        partyLord.transfer(address(this).balance);

        // Set withdrawal time for next year's party!
        lastPartyTimeCall = block.timestamp;

        // Tell the network, successful event
        emit onPushPayment(partyLord, _payout1, _payout2, block.timestamp);
        return true;
    }
}