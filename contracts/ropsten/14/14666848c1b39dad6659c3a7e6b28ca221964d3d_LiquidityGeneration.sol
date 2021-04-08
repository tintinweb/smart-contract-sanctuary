// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "SafeMath.sol";
import "Ownable.sol";

contract LiquidityGeneration is Ownable {
    using SafeMath for uint256;

    address[] internal investor;
    mapping(address => uint256) amount;

    uint256 totalRaised;
    uint256 endTime;
    constructor() {
      endTime = block.timestamp.add(600); // Open for Two Weeks
    }

    function invest() public payable { // SOME WEIRD ERROR
        require(block.timestamp < endTime, "Liquidity Generation Event has ended!");
        require(msg.value > 0, "No ETH sent!");
        (bool _isInvestor, ) = isInvestor(msg.sender);
        if (!_isInvestor) {
          investor.push(msg.sender);
          amount[msg.sender] = msg.value;
        }
        else {
          amount[msg.sender] = amount[msg.sender].add(msg.value);
        }
        totalRaised = totalRaised.add(msg.value);
      }

    function isInvestor(address _address)
        public
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < investor.length; s += 1){
            if (_address == investor[s]) return (true, s);
        }
        return (false, 0);
    }
    function getInvestors()
        public
        view
        returns(address[] memory)
    {
        return (investor);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function individualLiquidityTokenAmount(uint256 _totalTokensCreated, address _investor)
    public
    view
    returns(uint256)
    {
      uint256 _amount = _totalTokensCreated.div(totalRaised.div(amount[_investor]));
      return _amount;
    }

    function withdraw(address payable _to, uint256 _amount)
    public
    onlyOwner
    {
      require(_amount <= getBalance(), "Amount larger than contract holds!");
        (bool sent,) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
}