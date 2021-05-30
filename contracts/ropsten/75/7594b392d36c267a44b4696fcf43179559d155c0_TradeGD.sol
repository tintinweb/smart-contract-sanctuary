/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

pragma experimental ABIEncoderV2;

interface ERC20 {
    function mint(uint256 mintAmount) external returns (uint256);
    function balanceOf(address addr) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface Reserve {
    function buy(
        address _buyWith,
        uint256 _tokenAmount,
        uint256 _minReturn
    ) external returns (uint256);
}

contract TradeGD {
    ERC20 public GD;
    ERC20 public DAI;
    ERC20 public cDAI;
    Reserve public reserve;
    address public commons;

    event GDTraded(
        address from,
        uint256 value,
        uint256 gd
    );

    /**
     * @dev initialize the addresses of the contract
     */
    constructor() {
        GD = ERC20(0x4738C5e91C4F809da21DD0Df4B5aD5f699878C1c);
        DAI = ERC20(0xB5E5D0F8C0cbA267CD3D7035d6AdC8eBA7Df7Cdd);
        cDAI = ERC20(0x6CE27497A64fFFb5517AA4aeE908b1E7EB63B9fF);
        reserve = Reserve(0x5810950BF9184F286f1C33b2cf80533D2CB274AF);
        commons = msg.sender;

        DAI.approve(
            address(cDAI),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        GD.approve(
            address(reserve),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
        cDAI.approve(
            address(reserve),
            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
        );
    }

    /**
     * @dev buy GD from reserve using DAI since reserve  is in cDAI
     * we first mint cDAI
     * @param _DAIAmount - the amount of DAI approved to buy G$ with
     * @param _minGDAmount - the min amount of GD to receive for buying with cDAI(via DAI)
     */
    function buyGDFromReserveWithDAI(
        uint256 _DAIAmount,
        uint256 _minGDAmount
    ) public returns (uint256) {
        require(_DAIAmount > 0, "DAI amount should not be 0");
        require(
            DAI.transferFrom(msg.sender, _DAIAmount),
            "must approve DAI first"
        );

        uint256 cdaiRes = cDAI.mint(_DAIAmount);
        require(cdaiRes == 0, "cDAI buying failed");
        uint256 cdai = cDAI.balanceOf(address(this));
        uint256 gd = reserve.buy(address(cDAI), cdai, _minGDAmount);
        require(gd > 0, "gd buying failed");
        emit GDTraded(
            msg.sender,
            _DAIAmount,
            gd
        );
        GD.transfer(msg.sender, gd);
        return gd;
    }
}