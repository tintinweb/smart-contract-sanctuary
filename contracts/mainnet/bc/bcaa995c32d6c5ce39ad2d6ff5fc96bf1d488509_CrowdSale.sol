import "Ownable.sol";
import "Token.sol";
pragma solidity 0.8.0;

contract CrowdSale is Ownable {
    Token public tokenSold;
    uint256 public rateInTokens;
    uint256 public minimumBuyBNB = 660000000000000000;
    bool public onlyWhitelisted = true;

    mapping(address => bool) public whitelistedAddress;
    mapping(address => uint256) public whitelistedAmount;

    constructor(Token TokenAdr, uint256 rate) {
        tokenSold = TokenAdr;
        rateInTokens = rate;
    }

    event TokensSold(address tokenBuyer, uint256 amountBought);

    function whiteListAddresses(address[] memory _whitelist, uint256 _amount)
        public
        onlyOwner
    {
        for (uint256 j = 0; j < _whitelist.length; j++) {
            whitelistedAmount[_whitelist[j]] = _amount;
            whitelistedAddress[_whitelist[j]] = true;
        }
    }

    function changeRate(uint256 newRate) public onlyOwner {
        rateInTokens = newRate;
    }

    function setMinimumBuyBNB(uint256 newMin) public onlyOwner {
        minimumBuyBNB = newMin;
    }

    function setOnlyWhitelisted(bool status) public onlyOwner {
        onlyWhitelisted = status;
    }

    function AdminWithdrawTokens(address _adr, uint256 _amount)
        public
        onlyOwner
    {
        tokenSold.transfer(_adr, _amount);
    }

    // Specify 0 and will withdraw all.
    function AdminWithdrawBNB(uint256 _value) public onlyOwner {
        uint256 total = address(this).balance;
        if (_value == 0) {
            payable(msg.sender).transfer(total);
        } else {
            require(_value >= total, "Too Much!");
            payable(msg.sender).transfer(_value);
        }
    }

    function buyTokens() public payable {
        require(msg.value >= minimumBuyBNB);
        uint256 value = (rateInTokens * msg.value) / 10**9;
        require(value > 0);
        if (onlyWhitelisted == true) {
            require(whitelistedAmount[msg.sender] >= value, "Incorrect value");
            require(
                whitelistedAddress[msg.sender] == true,
                "You are not whitelisted"
            );
            whitelistedAmount[msg.sender] =
                whitelistedAmount[msg.sender] -
                value;
        }
        tokenSold.transfer(msg.sender, value);
        emit TokensSold(msg.sender, value);
    }
}