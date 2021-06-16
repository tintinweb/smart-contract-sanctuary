pragma solidity ^0.7.0;

import "SafeMath.sol";
import "Ownable.sol";
import "LivePriceETH.sol";

contract LiquidityGeneration is Ownable, LivePrice {
    using SafeMath for uint256;

    address[] internal investor;
    mapping(address => uint256) public amount;
    mapping(address => uint256) internal score;

    uint256 public totalRaised;
    uint256 public endTime;

    uint256 oracleValueDivisor;

    constructor() {
      endTime = 1624730400;// 27 Jun, 6PM UTC //block.timestamp.add(604800); // Open for One Week
      oracleValueDivisor = 10**8;
    }
      function invest(address _investor) public payable {
          require(block.timestamp < endTime, "Liquidity Generation Event is closed!");
          require(msg.value > 0, "No ETH sent!");
          uint256 currentPrice = uint(getLatestPrice());
          (bool _isInvestor, ) = isInvestor(_investor);
          if (!_isInvestor) {
            investor.push(_investor);
          }
          amount[_investor] = amount[_investor].add(msg.value);
          totalRaised = totalRaised.add(msg.value);

          uint256 currentScore = currentPrice.mul(msg.value).div(oracleValueDivisor);
          currentScore = currentScore.add(currentScore.div(5)); // PreLiquidity Bonus
          score[_investor] = score[_investor].add(currentScore);
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
        return investor;
    }

    function getScores() public view returns (uint256[] memory) {
      uint256[] memory scores = new uint256[](investor.length);
      for (uint256 s = 0; s < investor.length; s += 1){
        scores[s] = score[investor[s]];
      }
      return scores;
    }

    function getTotalScore() public view returns (uint256 totalScore) {
      for (uint256 s = 0; s < investor.length; s += 1){
        totalScore = totalScore.add(score[investor[s]]);
      }
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function endFirstStage() public onlyOwner { // Set endTime to now
      endTime = block.timestamp;
    }

    function withdraw(address payable _to, uint256 _amount)
    public onlyOwner
    {
      require(_amount <= getBalance(), "Amount larger than contract holds!");
        (bool sent,) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
}