pragma solidity ^0.4.24;

interface token {
    function transfer(address receiver, uint amount) external returns(bool);
    function balanceOf(address who) external returns(uint256);
}

interface AddressRegistry {
    function getAddr(string AddrName) external returns(address);
}

contract Registry {
    address public RegistryAddress;
    address public deployer;
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
    constructor () public {
        deployer = msg.sender;
    }
    function setRegistryAddr(address rAddress) public {
        require(msg.sender == deployer);
        RegistryAddress = rAddress;
    }
}

interface MFund {
    function NonIssueDeposits() external payable;
}

contract MoatAsset is Registry {

    event etherReceived(uint val);
    function () public payable {
        emit etherReceived(msg.value);
    }

    constructor(address rAddress) public {
        RegistryAddress = rAddress;
    }    

    function SendEtherToFund(uint256 weiAmt) onlyAdmin public {
        MFund MoatFund = MFund(getAddress("fund"));
        MoatFund.NonIssueDeposits.value(weiAmt)();
    }

    function CollectERC20(address tokenAddress) onlyAdmin public {
        token tokenFunctions = token(tokenAddress);
        uint256 tokenBal = tokenFunctions.balanceOf(address(this));
        tokenFunctions.transfer(msg.sender, tokenBal);
    }

    function SendEtherToDex(uint256 weiAmt) onlyAdmin public {
        getAddress("dex").transfer(weiAmt);
    }

    function SendERC20ToDex(address tokenAddress) onlyAdmin public {
        token tokenFunctions = token(tokenAddress);
        uint256 tokenBal = tokenFunctions.balanceOf(address(this));
        tokenFunctions.transfer(getAddress("dex"), tokenBal);
    }

}