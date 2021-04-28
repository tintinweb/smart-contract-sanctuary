pragma solidity ^0.7.0;

import "SafeMath.sol";
import "Ownable.sol";
import "LivePriceETH.sol";

contract LiquidityGeneration is Ownable, LivePrice {
    using SafeMath for uint256;

    address[] internal investor;
    mapping(address => uint256) public amount;
    mapping(address => uint256) internal score;
    mapping(address => bool) public earlyBird;

    uint256 public totalRaised;
    uint256 public endTime;
    bool internal earlyBirdBool;

    mapping(address => uint256) allowed;

    constructor() {
      endTime = block.timestamp.add(1210000); // Open for Two Weeks
      earlyBirdBool = true;
    }

    function invest() public payable {
        require(block.timestamp < endTime, "Liquidity Generation Event is closed!");
        require(msg.value > 0, "No ETH sent!");
        uint currentPrice = getLatestPrice();
        (bool _isInvestor, ) = isInvestor(msg.sender);
        if (!_isInvestor) {
          investor.push(msg.sender);
          earlyBird[msg.sender] = earlyBirdBool;
        }
        amount[msg.sender] = amount[msg.sender].add(msg.value);
        totalRaised = totalRaised.add(msg.value);

        uint256 currentScore = currentPrice.mul(msg.value);
        if(earlyBirdBool) currentScore = currentScore.add(currentScore.div(5));
        score[msg.sender] = score[msg.sender].add(currentScore);
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

    function getScores() public view returns (uint256[] memory scores) {
      for (uint256 s = 0; s < investor.length; s += 1){
        scores[s] = score[investor[s]];
      }
    }

    function getTotalScore() public view returns (uint256 totalScore) {
      for (uint256 s = 0; s < investor.length; s += 1){
        totalScore = totalScore.add(score[investor[s]]);
      }
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function individualLiquidityTokenAmount(uint256 _totalLiquidityTokensCreated)
    public
    view
    returns(uint256[] memory liquidityTokens)
    {
      uint256 totalScore = getTotalScore();
      uint256[] memory scores = getScores();
      for (uint256 s = 0; s < investor.length; s += 1){
          liquidityTokens[s] =  _totalLiquidityTokensCreated.div(totalScore.div(scores[s]));
      }
    }

    function endFirstStage() public onlyOwner { // Remove earlyBird bonus and set endTime to now
      earlyBirdBool = false;
      endTime = block.timestamp;
    }

    function openNextStage() public onlyOwner { // Remove earlyBird bonus and add another 2 weeks time for the event
      earlyBirdBool = false;
      endTime = block.timestamp.add(1210000);
    }

    function approveFor(address _address, uint256 _amount) public onlyOwner{
      allowed[_address] = allowed[_address].add(_amount);
    }

    function withdraw(address payable _to, uint256 _amount)
    public
    {
      require(_amount <= getBalance(), "Amount larger than contract holds!");
      require(allowed[_to] >= _amount, "Allowance exceeded!");
      allowed[_to] = allowed[_to].sub(_amount);
        (bool sent,) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
    function changeOwner(address _address) public onlyOwner{
      transferOwnership(_address);
    }

    receive() external payable {}
}