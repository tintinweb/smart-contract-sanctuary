/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IBEP20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface IDEXRouter {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address owner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!OWNER");
        _;
    }

    function transferOwnership(address adr) external onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }
}

contract TokenMigrator is Ownable {
    address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IBEP20 public oldToken;
    IBEP20 public newToken;
    IDEXRouter public router;

    uint256[2] public rate = [1, 0];

    constructor(
        IBEP20 _oldToken,
        IBEP20 _newToken,
        IDEXRouter _router
    ) {
        // PANCAKE V1 ROUTER 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F
        // PANCAKE V2 ROUTER 0x10ED43C718714eb63d5aA57B78B54704E256024E
        router = _router;
        oldToken = _oldToken;
        _oldToken.approve(address(router), ~uint256(0));
        newToken = _newToken;
    }

    function exchange(uint256 amount) external {
        // Transfer old token from user
        uint256 gotTKN = oldToken.balanceOf(address(this));
        oldToken.transferFrom(msg.sender, address(this), amount);
        gotTKN = oldToken.balanceOf(address(this)) - gotTKN;
        // Swap and send BNB to owner
        address[] memory path = new address[](2);
        path[0] = address(oldToken);
        path[1] = WBNB;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(oldToken.balanceOf(address(this)), 0, path, owner, block.timestamp);
        // Send new token by current rate
        uint256 amountNew = (gotTKN * rate[1]) / rate[0];
        require(newToken.balanceOf(address(this)) >= amountNew, "Not enough of new token to send");
        newToken.transfer(msg.sender, amountNew);
    }

    function setRouter(IDEXRouter _router) external onlyOwner {
        router = _router;
        oldToken.approve(address(router), ~uint256(0));
    }

    function setRate(uint256 oldTokenQty, uint256 newTokenQty) external onlyOwner {
        rate = [oldTokenQty, newTokenQty];
    }

    function infoBundle(address holder)
        external
        view
        returns (
            uint256 allOld,
            uint256 balOld,
            uint256 balNew,
            uint256[2] memory rates,
            address newTkn,
            address oldTkn
        )
    {
        allOld = oldToken.allowance(holder, address(this));
        balOld = oldToken.balanceOf(holder);
        balNew = newToken.balanceOf(holder);
        rates = rate;
        newTkn = address(newToken);
        oldTkn = address(oldToken);
    }
}