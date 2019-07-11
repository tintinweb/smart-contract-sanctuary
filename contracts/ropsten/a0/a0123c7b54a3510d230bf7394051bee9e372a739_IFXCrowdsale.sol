/**
 *Submitted for verification at Etherscan.io on 2019-07-05
*/

pragma solidity ^0.5.8;

/*
    IdeaFeX Token crowdsale contract

    Deployed to     : (contract address after deployment; to be filled in for GitHub)
    IFX contract    : 0xf4b5b251c9d8080d670b175ed34b0e75cc9559ba
    Funds wallet    : 0x6924E015c192C0f1839a432B49e1e96e06571227 (will be managed)
    Supply for sale : 400,000,000.000000000000000000
    Rate            : 2000 IFX = 1 ETH
    Bonus           : 40% before 20% sold
                      30% between 20% and 40% sold
                      20% between 40% and 60% sold
                      10% between 60% and 80% sold
*/


/* Safe maths */

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "Addition overflow");
        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "Subtraction overflow");
        uint c = a - b;
        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a==0){
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "Multiplication overflow");
        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0,"Division by 0");
        uint c = a / b;
        return c;
    }
    function mod(uint a, uint b) internal pure returns (uint) {
        require(b != 0, "Modulo by 0");
        return a % b;
    }
}


/* ERC20 standard interface */

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed sender, address indexed recipient, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


/* Safe ERC20 */

library SafeERC20 {
    using SafeMath for uint;

    function safeTransferFrom(ERC20Interface token, address from, address recipient, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, recipient, value));
    }

    function callOptionalReturn(ERC20Interface token, bytes memory data) private {
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


/* No nested calls */

contract ReentrancyGuard {
    uint private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}


/* IFX crowdsale */

contract IFXCrowdsale is ReentrancyGuard {
    using SafeMath for uint;
    using SafeERC20 for ERC20Interface;

    // Addresses!!!
    ERC20Interface private _IFX = ERC20Interface(0x838CDA9957f803A633a0b94D3E793274194738c0);
    address payable private _fundingWallet = 0xE047200Aff068f75e495Cf1723F9335B371CA1B5;
    address payable private _tokenSaleWallet = 0x6924E015c192C0f1839a432B49e1e96e06571227;

    uint private _rate = 2000;
    uint private _weiRaised;
    uint private _ifxSold;
    uint private _bonus = 40;
    uint private _rateCurrent = 2800;

    event TokensPurchased(address indexed purchaser, uint256 value, uint256 amount);


    // Basics

    function () external payable {
        buyTokens(msg.sender);
    }

    function token() public view returns (ERC20Interface) {
        return _IFX;
    }

    function wallet() public view returns (address payable) {
        return _fundingWallet;
    }

    function rate() public view returns (uint) {
        return _rate;
    }

    function rateWithBonus() public view returns (uint){
        return _rateCurrent;
    }

    function bonus() public view returns (uint) {
        return _bonus;
    }

    function weiRaised() public view returns (uint) {
        return _weiRaised;
    }

    function ifxSold() public view returns (uint) {
        return _ifxSold;
    }


    // Default when people send ETH to contract address

    function buyTokens(address beneficiary) public nonReentrant payable {

        // Ensures that the call is valid
        require(beneficiary != address(0), "Beneficiary is 0x0");
        require(msg.value != 0, "Value is 0");

        // Obtain token amount
        _currentBonus();
        uint tokenAmount = msg.value.mul(_rateCurrent);

        // Ensures that the hard cap is not breached
        require(_ifxSold + tokenAmount < 400000000 * 10**18, "Hard cap reached");

        // Records the purchase internally
        _weiRaised = _weiRaised.add(msg.value);
        _ifxSold = _ifxSold.add(tokenAmount);

        // Process the purchase
        _IFX.safeTransferFrom(_tokenSaleWallet, beneficiary, tokenAmount);
        _fundingWallet.transfer(msg.value);

        // Announce the purchase event
        emit TokensPurchased(beneficiary, msg.value, tokenAmount);
    }


    // Bonus

    function _currentBonus() internal {
        if(_ifxSold < 800 * 10**18){
            _bonus = 40;
        } else if(_ifxSold >= 800 * 10**18 && _ifxSold < 160000000 * 10**18){
            _bonus = 30;
        } else if(_ifxSold >= 1600 * 10**18 && _ifxSold < 240000000 * 10**18){
            _bonus = 20;
        } else if(_ifxSold >= 2400 * 10**18 && _ifxSold < 320000000 * 10**18){
            _bonus = 10;
        } else if(_ifxSold > 3200 * 10**18){
            _bonus = 0;
        }

        // _rate === 2000
        // _rate / 100 === 20
        // (_bonus + 100) * _rate / 100 === _bonus * 20 + _rate
        _rateCurrent = _bonus * 20 + 2000;
    }
}