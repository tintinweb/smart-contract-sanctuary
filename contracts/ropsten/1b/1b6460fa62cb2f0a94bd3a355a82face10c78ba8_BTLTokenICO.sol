// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

import "./BTLToken.sol";

contract BTLTokenICO is BTLToken {
    address public admin;
    address payable public deposit;
    uint256 public hardCap = (_totalSupply * 40) / 100; // 40% of total supply
    uint256 public raisedAmount; // value in tokens
    uint256 public saleStart = block.timestamp;
    uint256 public saleEnd = block.timestamp + 5259492; // plus time in seconds.
    uint256 public tokenTradeStart = saleEnd + 604800; // tranferable after week.
    uint256 public maxInvestment = 1000000; // tokens
    uint256 public minInvestment = 5000; // tokens

    // intervals
    uint256 public saleStartFirstWeekEnds = saleStart + 604800;
    uint256 public saleStartSecondWeekEnds = saleStart + (604800 * 2);
    uint256 public saleStartThirdWeekEnds = saleStart + (604800 * 3);
    uint256 public saleStartForthWeekEnds = saleStart + (604800 * 4);

    enum State {
        beforeStart,
        running,
        afterEnd,
        halted
    }
    State public icoState;

    event Invest(address investor, uint256 value, uint256 tokens);

    constructor(address payable _deposit) {
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function halt() public onlyAdmin {
        icoState = State.halted;
    }

    function resume() public onlyAdmin {
        icoState = State.running;
    }

    function changeDepositeAddress(address payable _newDeposite)
        public
        onlyAdmin
    {
        deposit = _newDeposite;
    }

    function getCurrentState() public view returns (State) {
        if (icoState == State.halted) {
            return State.halted;
        } else if (block.timestamp < saleStart) {
            return State.beforeStart;
        } else if (block.timestamp >= saleStart && block.timestamp <= saleEnd) {
            return State.running;
        } else {
            return State.afterEnd;
        }
    }

    function getBonusTokens(uint256 tokens) public view returns (uint256) {
        uint256 totalToken = tokens;
        if (block.timestamp <= saleStartFirstWeekEnds) {
            totalToken = tokens + ((tokens * 40) / 100);
        } else if (
            block.timestamp > saleStartFirstWeekEnds &&
            block.timestamp <= saleStartSecondWeekEnds
        ) {
            totalToken = tokens + ((tokens * 30) / 100);
        } else if (
            block.timestamp > saleStartSecondWeekEnds &&
            block.timestamp <= saleStartThirdWeekEnds
        ) {
            totalToken = tokens + ((tokens * 20) / 100);
        } else if (
            block.timestamp > saleStartThirdWeekEnds &&
            block.timestamp <= saleStartForthWeekEnds
        ) {
            totalToken = tokens + ((tokens * 10) / 100);
        }
        return uint256(totalToken);
    }

    function invest(uint256 tokens) public payable returns (bool) {
        icoState = getCurrentState();
        require(icoState == State.running, "ICO not running.");
        require(
            tokens >= minInvestment && tokens <= maxInvestment,
            "ICO purchased token is not valid."
        );
        
        uint256 totalTokens = getBonusTokens(tokens);
        require(
            raisedAmount + totalTokens >= hardCap,
            "ICO tokens sale hard cap reached."
        );
        
        deposit.transfer(msg.value);
        emit Invest(msg.sender, msg.value, totalTokens);
        allowed[deposit][msg.sender] = totalTokens;
        super.transferFrom(deposit, msg.sender, totalTokens);
        return true;
    }

    function transfer(address to, uint256 tokens)
        public
        override
        returns (bool success)
    {
        require(block.timestamp >= tokenTradeStart);
        raisedAmount += tokens;
        super.transfer(to, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public override returns (bool success) {
        require(block.timestamp >= tokenTradeStart);
        super.transferFrom(from, to, tokens);
        return true;
    }

    function burn() public returns (bool success) {
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        balances[founder] = 0;
        return true;
    }
}