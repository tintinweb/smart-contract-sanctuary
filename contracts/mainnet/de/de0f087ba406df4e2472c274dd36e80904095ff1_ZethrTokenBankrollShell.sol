pragma solidity ^0.4.24;

contract ZTHInterface {
    function buyAndSetDivPercentage(address _referredBy, uint8 _divChoice, string providedUnhashedPass) public payable returns (uint);
    function balanceOf(address who) public view returns (uint);
    function transfer(address _to, uint _value)     public returns (bool);
    function transferFrom(address _from, address _toAddress, uint _amountOfTokens) public returns (bool);
    function exit() public;
    function sell(uint amountOfTokens) public;
    function withdraw(address _recipient) public;
}

// The Zethr Token Bankrolls aren&#39;t quite done being tested yet,
// so here is a bankroll shell that we are using in the meantime.

// Will store tokens & divs @ the set div% until the token bankrolls are fully tested & battle ready
contract ZethrTokenBankrollShell {
    // Setup Zethr
    address ZethrAddress = address(0xD48B633045af65fF636F3c6edd744748351E020D);
    ZTHInterface ZethrContract = ZTHInterface(ZethrAddress);
    
    address private owner;
    
    // Read-only after constructor
    uint8 public divRate;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor (uint8 thisDivRate) public {
        owner = msg.sender;
        divRate = thisDivRate;
    }
    
    // Accept ETH
    function () public payable {}
    
    // Buy tokens at this contract&#39;s divRate
    function buyTokens() public payable onlyOwner {
        ZethrContract.buyAndSetDivPercentage.value(address(this).balance)(address(0x0), divRate, "0x0");
    }
    
    // Transfer tokens to newTokenBankroll
    // Transfer dividends to master bankroll
    function transferTokensAndDividends(address newTokenBankroll, address masterBankroll) public onlyOwner {
        // Withdraw divs to new masterBankroll
        ZethrContract.withdraw(masterBankroll);
        
        // Transfer tokens to newTokenBankroll
        ZethrContract.transfer(newTokenBankroll, ZethrContract.balanceOf(address(this)));
    }
}