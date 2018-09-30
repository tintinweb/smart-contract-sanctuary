pragma solidity ^0.4.24;

interface token {
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address receiver, uint amount) external returns (bool);
    function balanceOf(address who) external returns(uint256);
}

interface AddressRegistry {
    function getAddr(string AddrName) external returns(address);
}

contract Registry {
    address public RegistryAddress;
    modifier onlyAdmin() {
        require(
            msg.sender == getAddress("admin"),
            "Permission Denied"
        );
        _;
    }
    function getAddress(string AddressName) internal view returns(address) {
        AddressRegistry aRegistry = AddressRegistry(RegistryAddress);
        address realAddress = aRegistry.getAddr(AddressName);
        require(realAddress != address(0), "Invalid Address");
        return realAddress;
    }
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

interface MoatAsset {
    function getBalance(address AssetHolder, address Token) external view returns (uint256 balance);
    function TransferAssets(address tokenAddress, uint amount, address sendTo) external;
    function UpdateBalance(address tokenAddr, uint amt, bool add, address target) external;
}

contract KyberTrade is Registry {

    event eKyber(address src, address dest, uint weiAmt, uint srcAmt);
    function ExecuteTrade(
        uint weiAmt,
        address src,
        address dest,
        uint srcAmt,
        uint slipRate
    ) public {
        MoatAsset MAFunctions = MoatAsset(getAddress("asset"));

        // Balance check
        uint UserBalance = MAFunctions.getBalance(msg.sender, src);
        require(UserBalance >= srcAmt, "Insufficient Balance");

        // Transfered asset from asset contract to resolver for kyber trade
        MAFunctions.TransferAssets(src, srcAmt, address(this));

        // Kyber Trade
        Kyber kyberFunctions = Kyber(getAddress("kyber"));
        uint destAmt = kyberFunctions.trade.value(weiAmt)(
            src,
            srcAmt,
            dest,
            getAddress("asset"),
            2**256 - 1,
            slipRate,
            0
        );

        // Updating Balance
        MAFunctions.UpdateBalance(src, srcAmt, false, msg.sender);
        MAFunctions.UpdateBalance(dest, destAmt, true, msg.sender);

    }

    function giveERC20AllowanceToKyber(address[] Tokens) public {
        for (uint i = 0; i < Tokens.length; i++) {
            token tokenFunctions = token(Tokens[i]);
            tokenFunctions.approve(getAddress("kyber"), 2**256 - 1);
        }
    }

}

contract MoatResolver is KyberTrade {

    function () public payable {}

    function TransferTokens(address tokenAddress, uint Amount) public onlyAdmin {
        token tokenFunctions = token(tokenAddress);
        if (Amount == 0) {
            uint256 tokenBal = tokenFunctions.balanceOf(address(this));
        } else {
            tokenBal = Amount;
        }
        tokenFunctions.transfer(getAddress("asset"), tokenBal);
    }

    function TransferEther(uint Amount) public onlyAdmin {
        getAddress("asset").transfer(Amount);
    }

    constructor(address rAddr) public {
        RegistryAddress = rAddr;
    }

}