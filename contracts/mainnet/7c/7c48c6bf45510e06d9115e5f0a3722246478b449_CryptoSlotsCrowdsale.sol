pragma solidity ^0.4.14;


library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

}


contract MintableToken {
    function mint(address _to, uint256 _amount) returns (bool);
}


contract CryptoSlotsCrowdsale is Ownable {
    using SafeMath for uint256;

    MintableToken public token;

    bool public isCrowdsaleOpen = true;

    address public wallet;

    uint256 public rate = 400;

    uint256 public weiRaised;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 weiAmount, uint256 tokenAmount);

    event CrowdsaleFinished();

    function CryptoSlotsCrowdsale() {
        wallet = msg.sender;
    }

    function deleteContract() onlyOwner
    {
        selfdestruct(msg.sender);
    }

    function() payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) payable {
        require(beneficiary != 0x0);
        require(msg.value != 0);
        require(isCrowdsaleOpen);

        uint256 weiAmount = msg.value;

        uint256 tokenAmount = weiAmount.mul(rate);

        weiRaised = weiRaised.add(weiAmount);

        token.mint(beneficiary, tokenAmount);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokenAmount);

        wallet.transfer(msg.value);
    }

    function stopCrowdsale() onlyOwner {
        require(isCrowdsaleOpen);

        isCrowdsaleOpen = false;
        CrowdsaleFinished();
    }

    function setWallet(address value) onlyOwner {
        require(value != 0x0);
        wallet = value;
    }

    function setRate(uint value) onlyOwner {
        require(value != 0);
        rate = value;
    }

    function setToken(address value) onlyOwner {
        require(value != 0x0);
        token = MintableToken(value);
    }
}