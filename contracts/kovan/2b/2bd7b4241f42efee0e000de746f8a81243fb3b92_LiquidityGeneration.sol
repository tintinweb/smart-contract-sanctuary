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

    mapping(address => uint256) allowed;

    constructor() {
      endTime = block.timestamp.add(1210000); // Open for Two Weeks
    }

    function invest() public payable {
        require(block.timestamp < endTime, "Liquidity Generation Event is closed!");
        require(msg.value > 0, "No ETH sent!");
        uint256 currentPrice = uint(getLatestPrice());
        (bool _isInvestor, ) = isInvestor(msg.sender);
        if (!_isInvestor) {
          investor.push(msg.sender);
        }
        amount[msg.sender] = amount[msg.sender].add(msg.value);
        totalRaised = totalRaised.add(msg.value);

        uint256 currentScore = currentPrice.mul(msg.value);
        currentScore = currentScore.add(currentScore.div(5)); // PreLiquidity Bonus
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

    function endFirstStage() public onlyOwner { // Set endTime to now
      endTime = block.timestamp;
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