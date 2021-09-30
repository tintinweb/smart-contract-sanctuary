/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

pragma solidity ^0.5.12;

interface ERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

contract TNIVault {
    using SafeMath for uint256;
    ERC20 public TNIToken;

    uint256 public price;
    uint256 public weiRaised;
    uint256 public tokensSold;
    uint256 public saleSupply;

    uint256 public lockedTokens;

    bool public enableSale;

    address payable public governance;

    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    constructor(address payable _governance, ERC20 _TNIToken) public {
        governance = _governance;
        TNIToken = _TNIToken;
        price = 20;
        saleSupply = 1000000 * 10**(18);
        enableSale = true;
    }

    function() external payable {
        buyTNI(msg.sender);
    }

    function buyTNI(address beneficiary) public payable {
        uint256 tokens = 0;
        uint256 weiAmount = msg.value;

        tokens = SafeMath.add(tokens, weiAmount.mul(price));
        weiRaised = weiRaised.add(weiAmount);

        tokensSold = tokensSold + (tokens);
        saleSupply = saleSupply - (tokens);

        require(saleSupply != 0, "Sale supply ended !");

        // // tokens are transfering from here
        require(
            TNIToken.transfer(beneficiary, tokens),
            "Transfer not successful"
        );

        // Eth amount is going to owner
        governance.transfer(weiAmount);

        emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    }

    function setPrice(uint256 _price) public {
        require(msg.sender == governance, "!governance");
        price = _price;
    }

    function setEnableSale(bool _onOrOff) public {
        require(msg.sender == governance, "!governance");
        enableSale = _onOrOff;
    }

    function setSaleSupply(uint256 _saleSupply) public {
        require(msg.sender == governance, "!governance");
        saleSupply = _saleSupply;
    }

    function setGovernance(address payable _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }
}