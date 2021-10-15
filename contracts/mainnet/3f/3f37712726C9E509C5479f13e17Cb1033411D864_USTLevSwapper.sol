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
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function approve(address _spender, uint256 _value) external returns (bool);
    function add_liquidity(uint256[3] memory amounts, uint256 _min_mint_amount) external;
}

interface IBentoBoxV1 {
    function withdraw(IERC20 token, address from, address to, uint256 amount, uint256 share) external returns(uint256, uint256);
    function deposit(IERC20 token, address from, address to, uint256 amount, uint256 share) external returns(uint256, uint256);
}

contract USTLevSwapper {

     // Local variables
    IBentoBoxV1 public constant bentoBox = IBentoBoxV1(0xF5BCE5077908a1b7370B9ae04AdC565EBd643966);
    CurvePool public constant MIM3POOL = CurvePool(0x5a6A4D54456819380173272A5E8E9B9904BdF41B);
    CurvePool constant public UST3POOL = CurvePool(0x890f4e345B1dAED0367A877a1612f86A1f86985f);
    IERC20 public constant MIM = IERC20(0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3);
    IERC20 public constant UST = IERC20(0xa47c8bf37f92aBed4A126BDA807A7b7498661acD);
    IERC20 public constant ThreePOOL = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);

    constructor() public {
        MIM.approve(address(MIM3POOL), type(uint256).max);
        ThreePOOL.approve(address(UST3POOL), type(uint256).max);
        UST.approve(address(bentoBox), type(uint256).max);
    }


    // Swaps to a flexible amount, from an exact input amount
    function swap(
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public returns (uint256 extraShare, uint256 shareReturned) {

        (uint256 amountFrom, ) = bentoBox.withdraw(MIM, address(this), address(this), 0, shareFrom);

        uint256 amountIntermediate = MIM3POOL.exchange(0, 1, amountFrom, 0);

        uint256 amountTo = UST3POOL.exchange(1, 0, amountIntermediate, 0);

        (, shareReturned) = bentoBox.deposit(UST, address(this), recipient, amountTo, 0);
        extraShare = shareReturned - shareToMin;
    }
}