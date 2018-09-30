pragma solidity ^0.4.24;

interface AddressRegistry {
    function getAddr(string AddrName) external returns(address);
}

interface token {
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address receiver, uint amount) external returns (bool);
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
    address public RegistryAddress;
    modifier onlyAdmin() {
        require(
            msg.sender == getAddress("admin"),
            "Permission Denied");
        _;
    }
    function getAddress(string AddressName) internal view returns(address) {
        AddressRegistry aRegistry = AddressRegistry(RegistryAddress);
        address realAddress = aRegistry.getAddr(AddressName);
        require(realAddress != address(0), "Invalid Address");
        return realAddress;
    }
}

contract KyberTrade is Registry {

    mapping(address => mapping(address => uint)) Balances; // Depositor >> Token Address >> Balance
    address ETH = 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    function getBalance(address AssetHolder, address Token) public view returns (uint256 balance) {
        return Balances[AssetHolder][Token];
    }

    event eKyber(address src, address dest, uint weiAmt, uint srcAmt);
    function ExecuteTrade(
        uint weiAmt,
        address src,
        address dest,
        uint srcAmt,
        uint slipRate
    ) public {
        require(Balances[msg.sender][src] >= srcAmt, "Not enough balance"); // or instead have assertion it will automatically fail
        Kyber kyberFunctions = Kyber(getAddress("kyber"));
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

    function ApproveERC20(address[] Tokens) public {
        for (uint i = 0; i < Tokens.length; i++) {
            token tokenFunctions = token(Tokens[i]);
            tokenFunctions.approve(getAddress("kyber"), 2**256 - 1);
        }
    }
}

contract MoatAssets is KyberTrade {

    function () public payable {}

    function Deposit() public payable {
        Balances[msg.sender][ETH] += msg.value;
    }

    function Withdraw(address addr, uint amt) public {
        require(Balances[msg.sender][addr] >= amt, "Insufficient Balance");
        Balances[msg.sender][addr] -= amt;
        if (addr == ETH) {
            msg.sender.transfer(amt);
        } else {
            token tokenFunctions = token(addr);
            tokenFunctions.transfer(msg.sender, amt);
        }
    }

    function TransferTokens(address tokenAddress, uint Amount) public {
        require(
            msg.sender == getAddress("resolver"),
            "Permission Denied"
        );
        token tokenFunctions = token(tokenAddress);
        tokenFunctions.transfer(getAddress("reserve"), Amount);
    }

    constructor(address rAddr) public {
        RegistryAddress = rAddr;
    }

}