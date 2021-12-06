/**
 *Submitted for verification at FtmScan.com on 2021-12-06
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IPriceStrategy{
    function calcPercentage(
        uint8 bondType,
        uint hecPrice,
        uint bondPrice,
        uint roi5day,
        uint perBondDiscount) external view returns (uint);
    function bondTypes(address bond) external view returns(uint8);
    function getPrice(address _hecdai) external view returns (uint);
    function getBondPrice(address bond) external view returns (uint);
    function getRoiForDays(uint numberOfDays) external view returns (uint);
    function perBondDiscounts(address bond) external view returns(uint);
}
contract PriceStrategyViewer{
    IPriceStrategy public strategy;
    constructor(
        address _strategy
    ){
        require(_strategy!=address(0));
        strategy=IPriceStrategy(_strategy);
    }
    function calcPercentage(address hecpair,address bond) public view returns (
        uint8 _bondType,
        uint _hecPrice,
        uint _bondPrice,
        uint _5dayRoi,
        uint _perBondDiscount,
        uint _calPct,
        uint _actualPct
    ){
        _bondType=strategy.bondTypes(bond);
        _hecPrice=strategy.getPrice(hecpair);
        _bondPrice=strategy.getBondPrice(bond);
        _5dayRoi=strategy.getRoiForDays(5);
        _perBondDiscount=strategy.perBondDiscounts(bond);
        _calPct = strategy.calcPercentage(
            _bondType,
            _hecPrice,
            _bondPrice,
            _5dayRoi,
            _perBondDiscount
        );
        if(_calPct>11000) _actualPct=11000;
        else if(_calPct<9000) _actualPct=9000;
        else if(_calPct>=10100||_calPct<=9900) _actualPct=_calPct;
        else _actualPct=10000;
    }
}