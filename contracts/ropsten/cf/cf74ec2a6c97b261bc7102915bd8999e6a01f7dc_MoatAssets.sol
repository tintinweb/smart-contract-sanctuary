pragma solidity ^0.4.24;

interface AddressRegistry {
    function getAddr(string AddrName) external returns(address);
}

interface token {
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address receiver, uint amount) external returns (bool);
}

contract Registry {
    address public RegistryAddress;
    modifier onlyResolver() {
        require(
            msg.sender == getAddress("resolver"),
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

contract MoatAssets is Registry {

    mapping(address => mapping(address => uint)) Balances; // AssetOwner >> TokenAddress >> Balance (as per respective decimals)
    address ETH = 0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;

    function getBalance(
        address AssetHolder,
        address Token
    ) public view returns (uint256 balance) {
        return Balances[AssetHolder][Token];
    }

    function () public payable {}

    function Deposit() public payable {
        Balances[msg.sender][ETH] += msg.value;
    }

    function Withdraw(
        address addr,
        uint amt
    ) public {
        require(Balances[msg.sender][addr] >= amt, "Insufficient Balance");
        Balances[msg.sender][addr] -= amt;
        if (addr == ETH) {
            msg.sender.transfer(amt);
        } else {
            token tokenFunctions = token(addr);
            tokenFunctions.transfer(msg.sender, amt);
        }
    }

    //
    // Moat Resolver Function Starts
    //

    function UpdateBalance(
        address tokenAddr,
        uint amt,
        bool add,
        address target
    ) public onlyResolver {
        if (add) {
            Balances[target][tokenAddr] += amt;
        } else {
            Balances[target][tokenAddr] -= amt;
        }
    }

    function TransferAssets(
        address tokenAddress,
        uint amount,
        address sendTo
    ) public onlyResolver {
        if (tokenAddress == ETH) {
            sendTo.transfer(amount);
        } else {
            token tokenFunctions = token(tokenAddress);
            tokenFunctions.transfer(sendTo, amount);
        }
    }
    
    //
    // Moat Resolver Function Ends
    //

    constructor(address rAddr) public {
        RegistryAddress = rAddr;
    }

}