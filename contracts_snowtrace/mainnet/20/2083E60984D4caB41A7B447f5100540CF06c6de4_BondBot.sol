/**
 *Submitted for verification at snowtrace.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface ILPBOND {
    function redeem(address _recipient, bool _stake) external returns (uint);

    function Time() external view returns (address);
    function Rug() external view returns (address);

    function currentDebt() external view returns (uint256);

    function pendingPayoutFor(address _depositor)
        external
        view
        returns (uint256 pendingPayout_);

}

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract BondBot {
    event BondRedeemed(address indexed bond, uint256 indexed amount);

    // CONTRACTS
    // RUG:                0xb8EF3a190b68175000B74B4160d325FD5024760e
    // SRUG:               0xF3caa368B06033a83a49317549b3c1b47E7D5F8F
    // RUG STAKING HELPER: 0x6400DB179D786EB63661c012A9B6Ed7f30C3A435
    // BENQI:              0x96a03ff213d47d0556a6bd454779e59c12722d19
    // AVAXRUGLP:          0x8a4e5b690edfa273e59f28bbe2302aceeceefc41
    // AVAXRUGRLP:         0x881a8ece1cd45a458eacba97f45b0fbc0752fcbf
    // default: ["0x8a4e5b690edfa273e59f28bbe2302aceeceefc41","0x881a8ece1cd45a458eacba97f45b0fbc0752fcbf"]
    // constructor: 0xb8EF3a190b68175000B74B4160d325FD5024760e, 0xF3caa368B06033a83a49317549b3c1b47E7D5F8F


    // OHM TEST
    // OHM: 0x383518188C0C6d7730D91b2c03a03C837814a899
    // DAI: 0xca7b90f8158A4FAA606952c023596EE6d322bcf0
    // STAKING HELPER: 0xf73f23Bb0edCf4719b12ccEa8638355BF33604A1

    // IERC20 public token;
    // IERC20 public staked;

    // constructor(address _stakingHelper, address _token) {
    //     require(_stakingHelper != address(0));
    //     stakingHelper = StakingHelper(_stakingHelper);
    //     require(_token != address(0));
    //     token = IERC20(_token);
    // }

    // constructor(address _token, address _staked) {
    //     require(_token != address(0));
    //     token = IERC20(_token);
    //     require(_staked != address(0));
    //     staked = IERC20(_staked);
    // }

    function redeemAndStakeAll(address[] calldata _lpBonds) external {
        uint256 arrayLen = _lpBonds.length;
        for (uint256 i = 0; i < arrayLen; i++) {
            ILPBOND bond = ILPBOND(_lpBonds[i]);
            if (bond.pendingPayoutFor(msg.sender) == 0) continue;
            uint256 val = bond.redeem(msg.sender, true);
            emit BondRedeemed(_lpBonds[i], val);
        }
    }

    // Retrieve payout pending
    function retrievePendingPayoutAll(address[] calldata _lpBonds) view external returns (uint) {
        uint bal = 0;
        uint256 arrayLen = _lpBonds.length;
        for (uint256 i = 0; i< arrayLen; i++) {
            bal += ILPBOND(_lpBonds[i]).pendingPayoutFor(msg.sender);
        } 
        return bal;
    }

    // function redeemManually(address _lpBond ) external {
      
    //     TimeBondDepository ilp = TimeBondDepository(_lpBond);
    //     ilp.redeem(msg.sender, false);
    //     // emit BondRedeemed(lpBond, val);
    // }

    // function stake( uint _amount ) internal{
    //     if (token.balanceOf(msg.sender) <= _amount ) return;
    //     token.approve( 0xf73f23Bb0edCf4719b12ccEa8638355BF33604A1, _amount );
    //     stakingHelper.stake( _amount, msg.sender );
    // }

}