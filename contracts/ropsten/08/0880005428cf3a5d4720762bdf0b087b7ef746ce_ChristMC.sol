// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./ERC20Burnable.sol";
import './Crowdsale.sol';


contract ChristMC is ERC20, Ownable, ERC20Burnable, Crowdsale {
    using SafeMath for uint256;
    using Address for address;
    // using SafeERC20 for IERC20;
    
    // address public owner = msg.sender;
    uint256 kudi;
    
    address public teamWallet = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address public buyBackWallet = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;
    address public marketingWallet = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address public charityWallet = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
    
    uint256 private taxFee = 4;
    
    uint256 public minBuyAmount = 10**18;
    uint256 public maxBuyAmount = 100 * 10**18;
    uint256 public cap = 100*10**18;
    
    mapping(address => uint256) private _balanceOf;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    constructor (uint256 _rate, address payable _wallet, ERC20Burnable _token) Crowdsale(_rate, _wallet, _token) ERC20("ChristianMC", "CMC")
    {
        // _token.mint(teamWallet, 100000000000*10**18);
        _mint(msg.sender, 10000000000000 * 10 ** 18);
    }
    
    // functions to distribute tokens to wallets 
    function setTeamWallet() public onlyOwner {
        kudi = 100000000000*10**18;
        increaseAllowance(teamWallet, kudi);
        // approve(msg.sender, _balanceOf[msg.sender].mul(1).div(100));
        // _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(_balanceOf[msg.sender].mul(1).div(100));
        // _balanceOf[teamWallet] = _balanceOf[teamWallet].add(_balanceOf[msg.sender].mul(1).div(100));
        transfer(teamWallet, kudi);
    }
    
    function setBuyBackWallet() public onlyOwner{
        kudi = 500000000000*10**18;
        // _balanceOf[buyBackWallet].add(_balanceOf[msg.sender].mul(5).div(100));
        transfer(buyBackWallet, kudi);
    }
    
    function setMarketingWallet() public onlyOwner{
        kudi = 700000000000*10**18;
        // _balanceOf[marketingWallet].add(_balanceOf[msg.sender].mul(7).div(100));
        transfer(marketingWallet, kudi);
    }
    
    function setCharityWallet() public onlyOwner{
        kudi = 1600000000000*10**18;
        // _balanceOf[charityWallet].add(_balanceOf[msg.sender].mul(16).div(100));
        transfer(charityWallet, kudi);
    }
    
    // function rate() public view override(Crowdsale) returns (uint256) {
    //     return 5*10**7;
    // }
    
    function _getTokenAmount(uint256 weiAmount) internal view override(Crowdsale) returns (uint256) {
        uint256 amount = weiAmount * rate();
        uint256 _taxFee = (amount * taxFee) / 100;
        return amount - _taxFee;
    }
    
    // function cap() external view returns(uint256){
    //     return 100*10**18;
    // }
    
    function _preValidatePurchase(address beneficiary, uint256 weiAmount)
        internal
        view
        override(Crowdsale)
    {
        Crowdsale._preValidatePurchase(beneficiary, weiAmount);
        require(weiRaised() <= cap, 'CMC: value sent exceeds cap of stage');
    }
    
    
}