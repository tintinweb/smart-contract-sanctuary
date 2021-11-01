// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Auth.sol";

interface IDexRouter {
    function WETH() external pure returns (address);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

interface Dividends {
    function deposit() external payable;
}

contract ShoujoOwnership is Auth {

    address public cryptoShoujo;
    address public nftDividends;
    address public hibiki;
    bool public doDividends = false;
    bool public doBuyback = false;
    uint256 public buybackAccumulated = 0;
    uint256 public dividendDivisor = 5;
    uint256 public buybackDivisor = 2;
    IDexRouter router;
    
    constructor(address cs, address rout, address nftd, address bikky) Auth(msg.sender) {
        cryptoShoujo = cs;
        router = IDexRouter(rout);
        nftDividends = nftd;
        hibiki = bikky;
    }

    // Receive BNB
    receive() payable external {}

    function run() external {
        uint256 total = address(this).balance;
        if (doDividends) {
            uint256 divs = total / dividendDivisor;
            Dividends(nftDividends).deposit{value: divs}();
            total -= divs;
        }
        if (doBuyback) {
            uint256 bb = total / buybackDivisor;
            buybackAccumulated += bb;
            total -= bb;
        }
        payable(owner).transfer(total);
    }

    function recover() external authorized {
        payable(owner).transfer(address(this).balance);
    }

    function recoverOwnership() external authorized {
        Auth(cryptoShoujo).transferOwnership(payable(msg.sender));
    }

    function forceBuyback() external authorized {
        buyHibiki(buybackAccumulated);
    }

    function buyHibiki(uint256 amount) internal {
		address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = hibiki;

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            0x000000000000000000000000000000000000dEaD,
            block.timestamp + 300
        );
	}

    function setRouter(address rout) external authorized {
		router = IDexRouter(rout);
	}

    function setDividends(bool active, address addy, uint256 divisor) external authorized {
        nftDividends = addy;
        doDividends = active;
        dividendDivisor = divisor;
    }

    function setBuyback(bool active) external authorized {
        doBuyback = active;
    }

    function setHibiki(address bikky) external authorized {
        hibiki = bikky;
    }

    function setShoujo(address cs) external authorized {
        cryptoShoujo = cs;
    }
}