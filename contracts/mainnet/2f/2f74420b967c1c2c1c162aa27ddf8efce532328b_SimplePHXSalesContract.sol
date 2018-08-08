pragma solidity ^0.4.20;

/*
*   Basic PHX-Ethereum PHX Sales Contract
*
*   This contract keeps a list of offers to sell PHX coins
*   and acts as a market-maker matching sellers to buyers.
*   
* //*** Developed By:
*   _____       _         _         _ ___ _         
*  |_   _|__ __| |_  _ _ (_)__ __ _| | _ (_)___ ___ 
*    | |/ -_) _| &#39; \| &#39; \| / _/ _` | |   / (_-</ -_)
*    |_|\___\__|_||_|_||_|_\__\__,_|_|_|_\_/__/\___|
*   
*   &#169; 2018 TechnicalRise.  Written in March 2018.  
*   All rights reserved.  Do not copy, adapt, or otherwise use without permission.
*   https://www.reddit.com/user/TechnicalRise/
*  
*/

contract ERC20Token {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);
}

contract SimplePHXSalesContract {
    
    // ScaleFactor
    // It needs to be possible to make PHX cost less than 1 Wei / Rise
    uint public ScaleFactor = 10 ** 18;  
    
    // Array of offerors
    mapping(uint256 => address) public offerors;
	mapping(address => uint256) public AddrNdx;
    uint public nxtAddr;
    
	// Array between each address and their tokens offered and buy prices.
	mapping(address => uint256) public tokensOffered;
	mapping(address => uint256) public pricePerToken; // In qWeiPerRise (need to multiply by 10 ** 36 to get it to ETH / PHX)

    ERC20Token public phxCoin;

    address public owner;

    function SimplePHXSalesContract() public {
        phxCoin = ERC20Token(0x14b759A158879B133710f4059d32565b4a66140C); // Initiates a PHX Coin !important -- Make sure this is the existing contract!
        owner = msg.sender;
        nxtAddr = 1; // This is because all IDs in AddrNdx will initialize to zero
    }

    function offer(uint _tokensOffered, uint _tokenPrice) public {
        require(_humanSender(msg.sender));
        require(AddrNdx[msg.sender] == 0); // Make sure that this offeror has cancelled all previous offers
        require(phxCoin.transferFrom(msg.sender, this, _tokensOffered));
        tokensOffered[msg.sender] = _tokensOffered;
        pricePerToken[msg.sender] = _tokenPrice; // in qWeiPerRise
        offerors[nxtAddr] = msg.sender;
        AddrNdx[msg.sender] = nxtAddr;
        nxtAddr++;
    }

    function _canceloffer(address _offeror) internal {
        delete tokensOffered[_offeror];
        delete pricePerToken[_offeror];
        
        uint Ndx = AddrNdx[_offeror];
        nxtAddr--;

        // If this isn&#39;t the only offer, reshuffle the array
        // Moving the last entry to the middle of the list
        if (nxtAddr > 1) {
            offerors[Ndx] = offerors[nxtAddr];
            AddrNdx[offerors[nxtAddr]] = Ndx;
            delete offerors[nxtAddr];
        } else {
            delete offerors[Ndx];
        }
        
        delete AddrNdx[_offeror]; // !important
    }

    function canceloffer() public {
        if(AddrNdx[msg.sender] == 0) return; // No need to cancel non-existent offer
        phxCoin.transfer(msg.sender, tokensOffered[msg.sender]); // Return the Tokens
        _canceloffer(msg.sender);
    }
    
    function buy(uint _ndx) payable public {
        require(_humanSender(msg.sender));
        address _offeror = offerors[_ndx];
        uint _purchasePrice = tokensOffered[_offeror] * pricePerToken[_offeror] * ScaleFactor;
        require(msg.value >= _purchasePrice);
        phxCoin.transfer(msg.sender, tokensOffered[_offeror]);
        _offeror.transfer(_purchasePrice);
        _canceloffer(_offeror);
    }
    
    function updatePrice(uint _newPrice) public {
        // Make sure that this offeror has an offer out there
        require(tokensOffered[msg.sender] != 0); 
        pricePerToken[msg.sender] = _newPrice;
    }
    
    function getOfferor(uint _ndx) public constant returns (address _offeror) {
        return offerors[_ndx];
    }
    
    function getOfferPrice(uint _ndx) public constant returns (uint _tokenPrice) {
        return pricePerToken[offerors[_ndx]];
    }
    
    function getOfferAmount(uint _ndx) public constant returns (uint _tokensOffered) {
        return tokensOffered[offerors[_ndx]];
    }
    
    function withdrawEth() public {
        owner.transfer(address(this).balance);
    }
    
    function () payable public {
    }
    
    // Determine if the "_from" address is a contract
    function _humanSender(address _from) private view returns (bool) {
      uint codeLength;
      assembly {
          codeLength := extcodesize(_from)
      }
      return (codeLength == 0); // If this is "true" sender is most likely a Wallet
    }
}