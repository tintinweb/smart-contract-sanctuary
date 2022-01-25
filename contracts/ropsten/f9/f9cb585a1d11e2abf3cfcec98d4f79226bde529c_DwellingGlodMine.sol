// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './SafeMath.sol';
import './ERC20.sol';

contract DwellingGlodMine is ERC20 {
    using SafeMath for uint256;
    uint liquidityFee = 2;
    uint devFee = 2;
    address public owner;
    address public liquidity;
    address public dev;
    mapping(address => bool) public excliedFromTax;
    
    constructor(address _liquidity, address _dev) public ERC20('DwellingGlodMine', 'DGM'){
        _mint(msg.sender, 10000000 * 10 ** 18);
        owner = msg.sender;
        liquidity = _liquidity;
        dev = _dev;
        excliedFromTax[msg.sender] = true;
    }
    
    
    modifier onlyOwner(){
        require(msg.sender == owner, 'must be owner');
        _;
    }
    
    function getLiquidityFee() public view returns(uint){
        return liquidityFee;
    }
    
    function setLiquidityFee(uint _liquidityFee) public onlyOwner {
        liquidityFee = _liquidityFee;
    }
    
    function getDevFee() public view returns(uint){
        return devFee;
    }
    
    function setDevFee(uint _devFee) public onlyOwner {
        devFee = _devFee;
    }
    
    function setLiquidityAddress(address _liquidity) public onlyOwner {
        liquidity = _liquidity;
    }
    
    function setDevAddress(address _dev) public onlyOwner {
        dev = _dev;
    }
    
    function mint(uint256 _mintAmount) public onlyOwner{
        _mint(msg.sender, _mintAmount);
    }
    
    function burn(uint256 _mintAmount) public onlyOwner{
        _burn(msg.sender, _mintAmount);
    }
    
    function transfer(address resipient, uint256 amount) public override returns(bool){
        if(excliedFromTax[msg.sender] == true)
        {
            _transfer(_msgSender(), resipient, amount);
        } else
        {
            uint liquidityFeeAmount = amount.mul(liquidityFee) / 100;
            uint devFeeAmount = amount.mul(devFee) / 100;
            _transfer(_msgSender(), liquidity, liquidityFeeAmount);
            _transfer(_msgSender(), dev, devFeeAmount);
            _transfer(_msgSender(), resipient, amount.sub(liquidityFeeAmount).sub(devFeeAmount));
        }
        
        return true;
    }
}