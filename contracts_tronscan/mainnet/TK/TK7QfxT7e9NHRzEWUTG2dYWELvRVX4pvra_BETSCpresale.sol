//SourceUnit: BETSCpresale.sol

pragma solidity 0.5.12;

contract BETSCpresale {
    using SafeMath for uint;

    /*= VARIABLES =*/
    uint48 public tokensSold; // Tokens sold
    address payable public treasuryAddress; // Project address
    uint24 private constant tokenId = 1003482; // BETSC ID

    /*= EVENTS =*/
    event Sold(
        address indexed _buyerAddress,
        uint48 _amount
    );

    /*= PUBLIC FUNCTIONS =*/
    constructor() public {
        treasuryAddress = msg.sender;
    }

    function buyTokens() public payable {
        require(address(this).tokenBalance(tokenId) > 715, "No more tokens available");
        require(msg.value >= 5005000, "The minimum purchase amount is 5.005 TRX");

        uint48 tokenAmountConverted = uint48(msg.value.div(7000).mul(1000000));

        require(address(this).tokenBalance(tokenId) >= tokenAmountConverted, "Your purchase exceeds the number of available tokens");

        msg.sender.transferToken(tokenAmountConverted, tokenId);

        tokensSold = uint48(uint(tokensSold).add(tokenAmountConverted));

        treasuryAddress.transfer(msg.value);

        emit Sold(msg.sender, tokenAmountConverted);
    }

    function getRemainingTokens() public {
        require(msg.sender == treasuryAddress, "This function is valid only for the project treasury");
        treasuryAddress.transferToken(address(this).tokenBalance(tokenId), tokenId);
    }

    function getTokensBalance() public view returns(uint){
        return address(this).tokenBalance(tokenId);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}