pragma solidity ^0.4.24;

/** Proxy contract to buy tokens on Zethr,
 *  because we forgot to add the onTokenBuy event to Zethr.
 *  So we&#39;re proxying Zethr buys through this contract so that our website
 *  can properly track and display Zethr token buys.
**/
contract ZethrProxy {
    ZethrInterface zethr = ZethrInterface(address(0xD48B633045af65fF636F3c6edd744748351E020D));
    address owner = msg.sender;
    
    event onTokenPurchase(
        address indexed customerAddress,
        uint incomingEthereum,
        uint tokensMinted,
        address indexed referredBy
    );
    
    function buyTokensWithProperEvent(address _referredBy, uint8 divChoice) public payable {
        // Query token balance before & after to see how much we bought
        uint balanceBefore = zethr.balanceOf(msg.sender);
        
        // Buy tokens with selected div rate
        zethr.buyAndTransfer.value(msg.value)(_referredBy, msg.sender, "", divChoice);
        
        // Query balance after
        uint balanceAfter = zethr.balanceOf(msg.sender);
        
        emit onTokenPurchase(
            msg.sender,
            msg.value,
            balanceAfter - balanceBefore,
            _referredBy
        );
    }
    
    function () public payable {
        
    }
    
    // Yes there are tiny amounts of divs generated on buy,
    // but not enough to justify transferring to msg.sender - gas price makes it not worth it.
    function withdrawMicroDivs() public {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }
}

contract ZethrInterface {
    function buyAndTransfer(address _referredBy, address target, bytes _data, uint8 divChoice) public payable;
    function balanceOf(address _owner) view public returns(uint);
}