pragma solidity ^0.4.24;
/*   
 *    Exodus adaptation of OasisDirectProxy by MakerDAO.
 *    Work in progress; Second Mainnet iteration.
 */
contract OtcInterface {
    function sellAllAmount(address, uint, address, uint) public returns (uint);
    function buyAllAmount(address, uint, address, uint) public returns (uint);
    function getPayAmount(address, address, uint) public constant returns (uint);
}

contract TokenInterface {
    function balanceOf(address) public returns (uint);
    function allowance(address, address) public returns (uint);
    function approve(address, uint) public;
    function transfer(address,uint) public returns (bool);
    function transferFrom(address, address, uint) public returns (bool);
    function deposit() public payable;
    function withdraw(uint) public;
}

contract FeeInterface {
    function rateOf (address token) public view returns (uint);
    function takeFee (uint amt, address token) public view returns (uint fee, uint remaining);
}

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

contract Mortal is DSAuth {
    function kill() public auth {
        selfdestruct(owner);
    }
}

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

contract OasisMonetizedProxy is Mortal, DSMath {
    uint feePercentageWad;
    FeeInterface fees;
    constructor(FeeInterface _fees) public {
        fees = _fees;
    }
    
    function setFeeAuthority (FeeInterface newSource) public auth {
        fees = newSource;
    }
    
    function withdrawAndSend(TokenInterface wethToken, uint wethAmt) internal {
        wethToken.withdraw(wethAmt);
        require(msg.sender.call.value(wethAmt)());
    }

    /*** Public functions start here ***/
    
    function sellAllAmount(
        OtcInterface otc,
        TokenInterface payToken, 
        uint payAmt, 
        TokenInterface buyToken, 
        uint minBuyAmt
    ) public returns (uint) {
        require(payToken.transferFrom(msg.sender, this, payAmt));
        if (payToken.allowance(this, otc) < payAmt) {
            payToken.approve(otc, uint(-1));
        }
        uint buyAmt = otc.sellAllAmount(payToken, payAmt, buyToken, minBuyAmt);
        buyToken.balanceOf(this);
        (uint feeAmt, uint buyAmtRemainder) = fees.takeFee(buyAmt, buyToken);
        require(buyToken.transfer(owner, feeAmt)); /* fee is taken */
        require(buyToken.transfer(msg.sender, buyAmtRemainder));
        return buyAmtRemainder;
    }

    function sellAllAmountPayEth(
        OtcInterface otc,
        TokenInterface wethToken,
        TokenInterface buyToken,
        uint minBuyAmt
    ) public payable returns (uint) {
        wethToken.deposit.value(msg.value)();
        if (wethToken.allowance(this, otc) < msg.value) {
            wethToken.approve(otc, uint(-1));
        }
        uint buyAmt = otc.sellAllAmount(wethToken, msg.value, buyToken, minBuyAmt); 
        (uint feeAmt, uint buyAmtRemainder) = fees.takeFee(buyAmt, buyToken);
        require(buyToken.transfer(owner, feeAmt)); /* fee is taken */
        require(buyToken.transfer(msg.sender, buyAmtRemainder));
        return buyAmtRemainder;
    }

    function sellAllAmountBuyEth(
        OtcInterface otc,
        TokenInterface payToken, 
        uint payAmt, 
        TokenInterface wethToken, 
        uint minBuyAmt
    ) public returns (uint) {
        require(payToken.transferFrom(msg.sender, this, payAmt));
        if (payToken.allowance(this, otc) < payAmt) {
            payToken.approve(otc, uint(-1));
        }
        uint wethAmt = otc.sellAllAmount(payToken, payAmt, wethToken, minBuyAmt);
        (uint feeAmt, uint wethAmtRemainder) = fees.takeFee(wethAmt, wethToken);
        require(wethToken.transfer(owner, feeAmt)); /* fee is taken in WETH */ 
        withdrawAndSend(wethToken, wethAmtRemainder);
        return wethAmtRemainder;
    }

    function buyAllAmount(
        OtcInterface otc, 
        TokenInterface buyToken, 
        uint buyAmt, 
        TokenInterface payToken, 
        uint maxPayAmt
    ) public returns (uint payAmt) {
        uint payAmtNow = otc.getPayAmount(payToken, buyToken, buyAmt);
        require(payAmtNow <= maxPayAmt);
        require(payToken.transferFrom(msg.sender, this, payAmtNow));
        if (payToken.allowance(this, otc) < payAmtNow) {
            payToken.approve(otc, uint(-1));
        } 
        payAmt = otc.buyAllAmount(buyToken, buyAmt, payToken, payAmtNow);
        min(buyAmt, buyToken.balanceOf(this)); // To avoid rounding issues we check the minimum value
        (uint feeAmt, uint buyAmtRemainder) = fees.takeFee(buyAmt, buyToken);
        require(buyToken.transfer(owner, feeAmt)); /* fee is taken */
        require(buyToken.transfer(msg.sender, buyAmtRemainder)); 
    }

    function buyAllAmountPayEth(
        OtcInterface otc, 
        TokenInterface buyToken, 
        uint buyAmt, 
        TokenInterface wethToken
    ) public payable returns (uint wethAmt) {
        // In this case user needs to send more ETH than a estimated value, then contract will send back the rest
        wethToken.deposit.value(msg.value)();
        if (wethToken.allowance(this, otc) < msg.value) {
            wethToken.approve(otc, uint(-1));
        }
        wethAmt = otc.buyAllAmount(buyToken, buyAmt, wethToken, msg.value);
        buyAmt = min(buyAmt, buyToken.balanceOf(this)); // To avoid rounding issues we check the minimum value
        (uint feeAmt, uint buyAmtRemainder) = fees.takeFee(buyAmt, buyToken); 
        require(buyToken.transfer(owner, feeAmt)); /* fee is taken */
        require(buyToken.transfer(msg.sender, buyAmtRemainder)); 
        withdrawAndSend(wethToken, sub(msg.value, wethAmt)); /* return leftover eth */
    }

    function buyAllAmountBuyEth(
        OtcInterface otc, 
        TokenInterface wethToken, 
        uint wethAmt, 
        TokenInterface payToken, 
        uint maxPayAmt
    ) public returns (uint payAmt) {
        uint payAmtNow = otc.getPayAmount(payToken, wethToken, wethAmt);
        require(payAmtNow <= maxPayAmt);
        require(payToken.transferFrom(msg.sender, this, payAmtNow));
        if (payToken.allowance(this, otc) < payAmtNow) {
            payToken.approve(otc, uint(-1));
        }
        payAmt = otc.buyAllAmount(wethToken, wethAmt, payToken, payAmtNow);
        (uint feeAmt, uint wethAmtRemainder) = fees.takeFee(wethAmt, wethToken);
        require(wethToken.transfer(owner, feeAmt));
        withdrawAndSend(wethToken, wethAmtRemainder);
    }

    function() public payable {} /* fallback function */
}