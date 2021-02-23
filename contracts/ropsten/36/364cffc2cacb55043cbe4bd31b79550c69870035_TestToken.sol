pragma solidity ^0.7.6;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract TestToken is ERC20, ERC20Burnable, Ownable {

    using SafeMath for uint256;

    address[] internal poolholders;

    uint256 public profitPercent = 278;

    mapping(address => uint256) internal pools;

    mapping(address => uint256) internal profits;

    constructor () public ERC20("TestToken2", "TTK2") {
        _setupDecimals(6);
        _mint(msg.sender, 100000000 * (10 ** uint256(decimals())));
    }

    function createPool(uint256 _poolAmount) public
    {
        _burn(msg.sender, _poolAmount);
        if(pools[msg.sender] == 0) addPoolholder(msg.sender);
        pools[msg.sender] = pools[msg.sender].add(_poolAmount);
    }

    function removePool(uint256 _poolAmount) public
    {
        pools[msg.sender] = pools[msg.sender].sub(_poolAmount);
        if(pools[msg.sender] == 0) removePoolholder(msg.sender);
        _mint(msg.sender, _poolAmount);
    }

    function poolOf(address _poolholder) public view returns(uint256)
    {
        return pools[_poolholder];
    }

    function totalPools() public view returns(uint256)
    {
        uint256 _totalPools = 0;
        for (uint256 s = 0; s < poolholders.length; s += 1){
            _totalPools = _totalPools.add(pools[poolholders[s]]);
        }
        return _totalPools;
    }

    function isPoolholder(address _address) public view returns(bool, uint256)
    {
        for (uint256 s = 0; s < poolholders.length; s += 1){
            if (_address == poolholders[s]) return (true, s);
        }
        return (false, 0);
    }

    function addPoolholder(address _poolholder) public
    {
        (bool _isPoolholder, ) = isPoolholder(_poolholder);
        if(!_isPoolholder) poolholders.push(_poolholder);
    }

    function removePoolholder(address _poolholder) public
    {
        (bool _isPoolholder, uint256 s) = isPoolholder(_poolholder);
        if(_isPoolholder){
            poolholders[s] = poolholders[poolholders.length - 1];
            poolholders.pop();
        } 
    }

    function profitOf(address _poolholder) public view returns(uint256)
    {
        return profits[_poolholder];
    }

    function totalProfit() public view returns(uint256)
    {
        uint256 _totalProfit = 0;
        for (uint256 s = 0; s < poolholders.length; s += 1){
            _totalProfit = _totalProfit.add(profits[poolholders[s]]);
        }
        return _totalProfit;
    }

    function calculateProfit(address _poolholder) public view returns(uint256)
    {
        return pools[_poolholder] * profitPercent / 100000;
    }

    function accrueProfit() public onlyOwner
    {
        for (uint256 s = 0; s < poolholders.length; s += 1){
            address poolholder = poolholders[s];
            uint256 profit = calculateProfit(poolholder);
            profits[poolholder] = profits[poolholder].add(profit);
        }
    }

    function withdrawPoolProfit() public
    {
        uint256 reward = profits[msg.sender];
        profits[msg.sender] = 0;
        _mint(msg.sender, reward);
    }

}