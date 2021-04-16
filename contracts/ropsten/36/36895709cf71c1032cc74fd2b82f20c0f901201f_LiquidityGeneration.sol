// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "SafeMath.sol";
import "Ownable.sol";

contract LiquidityGeneration is Ownable {
    using SafeMath for uint256;

    address[] internal investor;
    mapping(address => uint256) public amount;
    mapping(address => bool) public earlyBird;

    uint256 public totalRaised;
    uint256 public endTime;
    bool internal earlyBirdBool;

    constructor() {
      endTime = block.timestamp.add(1210000); // Open for Two Weeks
      earlyBirdBool = true;
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
        earlyBird[msg.sender] = earlyBirdBool;
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

    function individualLiquidityTokenAmount(uint256 _totalLiquidityTokensCreated, address[] memory _investor)
    public
    view
    returns(uint256[] memory liquidityTokens)
    {
      uint256[] memory investorScore;
      uint256 totalScore;
      for (uint256 s = 0; s < _investor.length; s += 1){
          if(earlyBird[_investor[s]]) investorScore[s] = amount[_investor[s]].add(amount[_investor[s]].div(5));
          else investorScore[s] = amount[_investor[s]];
          totalScore = totalScore.add(investorScore[s]);
      }
      for (uint256 s = 0; s < _investor.length; s += 1){
          liquidityTokens[s] =  _totalLiquidityTokensCreated.div(totalScore.div(investorScore[s]));
      }
    }

    function goToNextStage() public onlyOwner {
      earlyBirdBool = false;
    }

    function withdraw(address payable _to, uint256 _amount)
    public
    onlyOwner
    {
      require(block.timestamp < endTime, "Event not over!");
      require(_amount <= getBalance(), "Amount larger than contract holds!");
        (bool sent,) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
}