pragma solidity ^0.4.24;

interface token {
    function approve(address spender, uint256 value) external returns (bool);
}

interface Kyber {
    function trade(
        address src,
        uint srcAmount,
        address dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    ) external payable returns (uint);
}

contract KyberTrade {

    mapping(address => mapping(address => uint)) public Balances; // Depositor >> Token Address >> Balance

    event eKyber(address src, address dest, uint weiAmt, uint srcAmt);
    address public KyberAddress;
    function ExecuteTrade(
        uint weiAmt,
        address src,
        address dest,
        uint srcAmt,
        uint slipRate
    ) public {
        require(Balances[msg.sender][src] >= srcAmt, "Not enough balance"); // or instead have assertion it will automatically fail
        Kyber kyberFunctions = Kyber(KyberAddress);
        uint destAmt = kyberFunctions.trade.value(weiAmt)(
            src,
            srcAmt,
            dest,
            address(this),
            2**256 - 1,
            slipRate,
            0
        );
        Balances[msg.sender][src] -= srcAmt;
        Balances[msg.sender][dest] += destAmt;
        emit eKyber(src, dest, weiAmt, srcAmt);
    }
}

contract MoatAssets is KyberTrade {

    event eDepositEther(address Depositor, uint EtherDeposits);
    event eWithdrawEther(address Withdrawer, uint EtherWithdrawn);

    address ETH = 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    function () public payable {
        Balances[msg.sender][ETH] += msg.value;
        emit eDepositEther(msg.sender, msg.value);
    }

    function WithdrawEther(uint EtherAmount) public {
        require(EtherAmount >= Balances[msg.sender][ETH], "You can&#39;t withdraw more than what you have.");
        Balances[msg.sender][ETH] -= EtherAmount;
        msg.sender.transfer(EtherAmount);
        emit eWithdrawEther(msg.sender, EtherAmount);
    }

    function ApproveERC20(address[] Tokens) public {
        for (uint i = 0; i < Tokens.length; i++) {
            token tokenFunctions = token(Tokens[i]);
            tokenFunctions.approve(KyberAddress, 2**256 - 1);
        }
    }

    constructor(address kAddress) public {
        KyberAddress = kAddress;
    }

}