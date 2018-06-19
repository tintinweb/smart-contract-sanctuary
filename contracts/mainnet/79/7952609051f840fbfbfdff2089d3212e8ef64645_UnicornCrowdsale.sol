pragma solidity ^0.4.24;


interface token {
    function transfer(address receiver, uint amount) public;
    function burn(uint256 _value) public returns (bool success);
}

contract Ownable {

    address public owner;

    function Constrctor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
}

contract UnicornCrowdsale is Ownable {
    
    uint256 public constant EXCHANGE_RATE = 1000;
    
    uint256 availableTokens;
    address addressToSendEthereum;
    
    uint public amountRaised;
    uint public price;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function UnicornCrowdsale (
        address _addressOfTokenUsedAsReward,
        address _addressToSendEthereum
    ) public {
        availableTokens = 100000000 * 10 ** 18;
        addressToSendEthereum = _addressToSendEthereum;
        tokenReward = token(_addressOfTokenUsedAsReward);
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () public payable {
        uint256 amount = msg.value;
        uint256 tokens = amount * EXCHANGE_RATE;
        balanceOf[msg.sender] += tokens;
        amountRaised += tokens;
        availableTokens -= tokens;
        tokenReward.transfer(msg.sender, msg.value * EXCHANGE_RATE);
        addressToSendEthereum.transfer(amount);
    }
    
    
    function sellForOtherCoins(address _address,uint amount)  public payable onlyOwner
    {
        uint256 tokens = amount;
        availableTokens -= tokens;
        tokenReward.transfer(_address, tokens);
    }
    
    function burnAfterIco() public onlyOwner returns (bool success){
        uint256 balance = availableTokens;
        tokenReward.burn(balance);
        availableTokens = 0;
        return true;
    }

    function tokensAvailable() public constant returns (uint256) {
        return availableTokens;
    }

}