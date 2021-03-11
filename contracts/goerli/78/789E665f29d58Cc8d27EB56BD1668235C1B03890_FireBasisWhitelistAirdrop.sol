pragma solidity >=0.7.0;

import '../Context.sol';
import '../Libraries.sol';

interface FireBasisWhitelistInterface {
    function queryUserAddr(uint256 _userId)
        external
        view
        returns (address addr);

    function queryUsersCount() external view returns (uint256 totalAmount);
}

contract FireBasisWhitelistAirdrop is Operator {
    address public fbcAddress;
    IERC20 public fbcContract;

    address public whitelistAddress;
    FireBasisWhitelistInterface public whitelist;

    constructor(address _fbc, address _whitelist) {
        fbcAddress = _fbc;
        whitelistAddress = _whitelist;

        whitelist = FireBasisWhitelistInterface(whitelistAddress);

        fbcContract = IERC20(fbcAddress);
    }

    //single address can receive amount
    uint256 public airdropFBCAmount = 5 * 1e18;
    uint256 public airdropAddressCount = 100;

    //target addresses
    address[] public targetAddresses;
    mapping(address => bool) addressExsit;

    ////////////////////////////////////////////////////////////////////////////////
    function withdrawToken() external onlyOperator {
        fbcContract.transfer(msg.sender, fbcContract.balanceOf(address(this)));
    }

    function doAirDrop() external {
        for (uint256 i = 0; i < targetAddresses.length; i++) {
            fbcContract.transfer(targetAddresses[i], airdropFBCAmount);
        }
    }

    //add address
    function addTargetAddress(address _addr) public onlyOperator {
        if (!addressExsit[_addr]) {
            targetAddresses.push(_addr);
            addressExsit[_addr] = true;
        }
    }

    //add address
    function importAddressFromWhitelist() external onlyOperator {
        uint256 count = whitelist.queryUsersCount();
        uint256 maxId = Math.min(count, airdropAddressCount);
        uint256 i = 1;
        for (i; i < maxId + 1; i++) {
            address addr = whitelist.queryUserAddr(i);
            addTargetAddress(addr);
        }
    }

    function queryAddressByIndex(uint256 index)
        external
        view
        returns (address addr)
    {
        addr = targetAddresses[index];
    }

    function queryAddressCount() external view returns (uint256 count) {
        count = targetAddresses.length;
    }
}