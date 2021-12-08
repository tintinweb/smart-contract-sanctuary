/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

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
    address public pendingGovernance;
    bool public breaker = false;
    int public threshold = 99000000;
    
    constructor(address _governance) {
        governance = _governance;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance);
        _;
    }

    function setGovernance(address _governance) external onlyGovernance {
        pendingGovernance = _governance;
    }

    function acceptGovernance() external {
        require(msg.sender == pendingGovernance);
        governance = pendingGovernance;
    }

    function setBreaker(bool _breaker) external onlyGovernance {
        breaker = _breaker;
    }

    function setThreshold(int _threshold) external onlyGovernance {
        threshold = _threshold;
    }

    function repayBorrow(cy20 repay, erc20 token, uint amount) external returns (bool) {
        token.approve(address(repay), amount);
        repay.repayBorrow(amount);
        return true;
    }

    function quote(address to, uint amount) external view returns (uint) {
        return ff.price(to) * amount / 1e18;
    }
    
    function swap(address to, uint amount, uint minOut) external returns (bool) {
        require(!breaker, "breaker");
        require(feed.latestAnswer() > threshold, "mim peg");
        _safeTransferFrom(mim, msg.sender, governance, amount);
        uint _quote = ff.price(to) * amount / 1e18;
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