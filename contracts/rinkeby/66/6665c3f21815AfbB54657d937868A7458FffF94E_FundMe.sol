//"SPDX-Licence-Identifier: MIT"

pragma solidity >=0.6.0 <0.9.0;

contract FundMe {
    mapping(address => uint256) public addressToFundedAmount;
    address public owner;
    address[] funders;

    constructor() public {
        owner = msg.sender;
    }

    function fund() internal {
        addressToFundedAmount[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    //  function getPrice() internal view returns(uint256){

    //      AggregatorV3Interface price = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
    //      (, int256 answer,,,) = price.latestRoundData();
    //      return uint256(answer);
    //  }

    function donateUSD() public payable returns (uint256) {
        //  uint256 price = getPrice()/100000000;
        //  uint256 minUSD = price/10;
        //  if(msg.value < (price/10)){
        //      return "Minimum amount to donate is 0.1 eth";
        //  }
        uint256 toEth = msg.value / 1000000000000000000;
        require(toEth > 1, "Minimum amount to donate is 1.1 eth");
        fund();
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);
        for (uint256 i = 0; i < funders.length; i++) {
            addressToFundedAmount[funders[i]] = 0;
        }

        funders = new address[](0);
    }
}