pragma solidity ^0.4.24;

interface token {
    function transfer(address receiver, uint amount) external returns (bool);
    function balanceOf(address who) external returns (uint256);
}

interface AddressRegistry {
    function getAddr(string AddrName) external returns(address);
}

contract Registry {
    address public RegistryAddress;
    modifier onlyAdmin() {
        require(msg.sender == getAddress("admin"));
        _;
    }
    function getAddress(string AddressName) internal view returns(address) {
        AddressRegistry aRegistry = AddressRegistry(RegistryAddress);
        address realAddress = aRegistry.getAddr(AddressName);
        require(realAddress != address(0));
        return realAddress;
    }
}

contract TokenMigration is Registry {

    address public MTUV1;
    mapping(address => bool) public Migrated;

    constructor(address prevMTUAddress, address rAddress) public {
        MTUV1 = prevMTUAddress;
        RegistryAddress = rAddress;
    }

    function getMTUBal(address holder) internal view returns(uint balance) {
        token tokenFunctions = token(MTUV1);
        return tokenFunctions.balanceOf(holder);
    }

    function Migrate() public {
        require(!Migrated[msg.sender]);
        Migrated[msg.sender] = true;
        token tokenTransfer = token(getAddress("unit"));
        tokenTransfer.transfer(msg.sender, getMTUBal(msg.sender));
    }

    function SendEtherToAsset(uint256 weiAmt) onlyAdmin public {
        getAddress("asset").transfer(weiAmt);
    }

    function CollectERC20(address tokenAddress) onlyAdmin public {
        token tokenFunctions = token(tokenAddress);
        uint256 tokenBal = tokenFunctions.balanceOf(address(this));
        tokenFunctions.transfer(msg.sender, tokenBal);
    }

}