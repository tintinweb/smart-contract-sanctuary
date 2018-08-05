pragma solidity ^0.4.24;

interface AddrReg {
    function getAddr(string AddrName) external returns(address);
}

interface token {
    function transfer(address receiver, uint amount) external returns(bool);
    function balanceOf(address who) external returns(uint256);
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

contract Registry {
    address public AddressRegistry;
    function getAddress(string AddressName) internal returns(address) {
        AddrReg aRegistry = AddrReg(AddressRegistry);
        address realAddress = aRegistry.getAddr(AddressName);
        require(realAddress != address(0));
        return realAddress;
    }
}

contract KyberTrade is Registry {

    mapping(address => mapping(address => uint)) public Balances; // FundManager >> Token Address >> Balance

    event eKyber(address src, address dest, uint weiAmt, uint srcAmt);
    address public KyberAddress;
    function ExecuteTrade(
        uint weiAmt,
        address src,
        address dest,
        uint srcAmt,
        uint slipRate
    ) public {
        uint estimatedDest = slipRate * srcAmt / 10**18;
        require(Balances[msg.sender][src] >= srcAmt); // or instead have assertion it will automatically fail
        Balances[msg.sender][src] -= srcAmt;
        Balances[msg.sender][dest] += estimatedDest;
        Kyber kyberFunctions = Kyber(KyberAddress);
        kyberFunctions.trade.value(weiAmt)(
            src,
            srcAmt,
            dest,
            address(this),
            2**256 - 1,
            slipRate,
            0
        );
        emit eKyber(src, dest, weiAmt, srcAmt);
    }
}

contract FundAssets is KyberTrade {

    event eDepositEther(address ManagerAddress, uint EtherDeposits);
    event fallbackEther(address sender, uint value);

    function DepositEther(address FundManager) public payable {
        Balances[FundManager][0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee] += msg.value; // overflow issue
        emit eDepositEther(FundManager, msg.value);
    }

    function ApproveERC20(address tokenAddress) public {
        token tokenFunctions = token(tokenAddress);
        tokenFunctions.approve(KyberAddress, 2**256 - 1);
    }

    function () public payable {
        emit fallbackEther(msg.sender, msg.value);
    }

    constructor(address rAddress, address kAddress) public {
        AddressRegistry = rAddress;
        KyberAddress = kAddress;
    }

}