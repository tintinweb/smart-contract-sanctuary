// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
interface CurvePool {
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
    function approve(address _spender, uint256 _value) external returns (bool);
    function add_liquidity(uint256[3] memory amounts, uint256 _min_mint_amount) external;
}

interface IBentoBoxV1 {
    function withdraw(IERC20 token, address from, address to, uint256 amount, uint256 share) external returns(uint256, uint256);
    function deposit(IERC20 token, address from, address to, uint256 amount, uint256 share) external returns(uint256, uint256);
}

contract USTLevSwapper {

     // Local variables
    IBentoBoxV1 public constant degenBox = IBentoBoxV1(0xd96f48665a1410C0cd669A88898ecA36B9Fc2cce);
    CurvePool constant public UST2POOL = CurvePool(0x55A8a39bc9694714E2874c1ce77aa1E599461E18);
    IERC20 public constant MIM = IERC20(0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3);
    IERC20 public constant UST = IERC20(0xa47c8bf37f92aBed4A126BDA807A7b7498661acD);

    constructor() public {
        MIM.approve(address(UST2POOL), type(uint256).max);
        UST.approve(address(degenBox), type(uint256).max);
    }


    // Swaps to a flexible amount, from an exact input amount
    function swap(
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public returns (uint256 extraShare, uint256 shareReturned) {

        (uint256 amountFrom, ) = degenBox.withdraw(MIM, address(this), address(this), 0, shareFrom);

        uint256 amountTo = UST2POOL.exchange(0, 1, amountFrom, 0, address(degenBox));

        (, shareReturned) = degenBox.deposit(UST, address(degenBox), recipient, amountTo, 0);
        extraShare = shareReturned - shareToMin;
    }
}