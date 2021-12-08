/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface erc20 {
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function balanceOf(address) external view returns (uint);
}

interface cy20 {
    function redeemUnderlying(uint) external returns (uint);
    function mint(uint) external returns (uint);
    function borrow(uint) external returns (uint);
    function repayBorrow(uint) external returns (uint);
}

interface registry {
    function cy(address) external view returns (address);
    function price(address) external view returns (uint);
}

interface cl {
    function latestAnswer() external view returns (int);
}

contract ibAMM {
    address constant mim = address(0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3);
    registry constant ff = registry(0x5C08bC10F45468F18CbDC65454Cbd1dd2cB1Ac65);
    cl constant feed = cl(0x7A364e8770418566e3eb2001A96116E6138Eb32F);
    
    address public governance;
    address public pending_governance;
    bool public breaker = false;
    int public threshold = 99000000;
    
    constructor(address _governance) {
        governance = _governance;
    }

    modifier only_governance() {
        require(msg.sender == governance);
        _;
    }

    function set_governance(address _governance) external only_governance {
        pending_governance = _governance;
    }

    function accept_governance() external {
        require(msg.sender == pending_governance);
        governance = pending_governance;
    }

    function set_breaker(bool _breaker) external only_governance {
        breaker = _breaker;
    }

    function set_threshold(int _threshold) external only_governance {
        threshold = _threshold;
    }

    function repay(cy20 cy, address token, uint amount) external returns (bool) {
         _safeTransferFrom(token, msg.sender, address(this), amount);
        erc20(token).approve(address(cy), amount);
        require(cy.repayBorrow(amount) == 0, "ib: !repay");
        return true;
    }

    function mim_feed() external view returns (int) {
        return feed.latestAnswer();
    }

    function quote(address to, uint amount) external view returns (uint) {
        return amount * 1e18 / ff.price(to);
    }
    
    function swap(address to, uint amount, uint minOut) external returns (bool) {
        require(!breaker, "breaker");
        require(feed.latestAnswer() > threshold, "mim peg");
        _safeTransferFrom(mim, msg.sender, governance, amount);
        uint _quote = amount * 1e18 / ff.price(to);
        require(_quote > 0 && _quote >= minOut, "< minOut");
        require(cy20(ff.cy(to)).borrow(_quote) == 0, "ib: borrow failed");
        _safeTransfer(to, msg.sender, _quote);
        return true;
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(erc20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}