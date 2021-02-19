/**
 *Submitted for verification at Etherscan.io on 2021-02-18
*/

// File: contracts\fixed-inflation\FixedInflationData.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

struct FixedInflationEntry {
    string name;
    uint256 blockInterval;
    uint256 lastBlock;
    uint256 callerRewardPercentage;
}

struct FixedInflationOperation {

    address inputTokenAddress;
    uint256 inputTokenAmount;
    bool inputTokenAmountIsPercentage;
    bool inputTokenAmountIsByMint;

    address ammPlugin;
    address[] liquidityPoolAddresses;
    address[] swapPath;
    bool enterInETH;
    bool exitInETH;

    address[] receivers;
    uint256[] receiversPercentages;
}

// File: contracts\fixed-inflation\IFixedInflationExtension.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;


interface IFixedInflationExtension {

    function init(address host) external;

    function setHost(address host) external;

    function data() external view returns(address fixedInflationContract, address host);

    function receiveTokens(address[] memory tokenAddresses, uint256[] memory transferAmounts, uint256[] memory amountsToMint) external;

    function flushBack(address[] memory tokenAddresses) external;

    function deactivationByFailure() external;

    function setEntry(FixedInflationEntry memory entryData, FixedInflationOperation[] memory operations) external;

    function active() external view returns(bool);

    function setActive(bool _active) external;
}

// File: contracts\fixed-inflation\util\DFOHub.sol

// SPDX_License_Identifier: MIT

pragma solidity ^0.7.6;

interface IDoubleProxy {
    function proxy() external view returns (address);
}

interface IMVDProxy {
    function getMVDFunctionalitiesManagerAddress() external view returns(address);
    function getMVDWalletAddress() external view returns (address);
    function getStateHolderAddress() external view returns(address);
    function submit(string calldata codeName, bytes calldata data) external payable returns(bytes memory returnData);
}

interface IMVDFunctionalitiesManager {
    function getFunctionalityData(string calldata codeName) external view returns(address, uint256, string memory, address, uint256);
    function isAuthorizedFunctionality(address functionality) external view returns(bool);
}

interface IStateHolder {
    function getUint256(string calldata name) external view returns(uint256);
    function getAddress(string calldata name) external view returns(address);
    function clear(string calldata varName) external returns(string memory oldDataType, bytes memory oldVal);
}

// File: contracts\fixed-inflation\IFixedInflation.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;


interface IFixedInflation {

    function setEntry(FixedInflationEntry memory entryData, FixedInflationOperation[] memory operations) external;

    function flushBack(address[] memory tokenAddresses) external;
}

// File: contracts\fixed-inflation\util\IERC20.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;

interface IERC20 {
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);
}

// File: contracts\fixed-inflation\dfo\DFOBasedFixedInflationExtension.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;






contract DFOBasedFixedInflationExtension is IFixedInflationExtension {

    string private constant FUNCTIONALITY_NAME = "manageFixedInflation";

    address private _host;

    address private _fixedInflationContract;

    bool public override active;

    modifier fixedInflationOnly() {
        require(_fixedInflationContract == msg.sender, "Unauthorized");
        _;
    }

    receive() external payable {
    }

    modifier hostOnly() {
        require(_isFromDFO(msg.sender), "Unauthorized");
        _;
    }

    function init(address doubleProxyAddress) override public {
        require(_host == address(0), "Already init");
        require((_host = doubleProxyAddress) != address(0), "blank host");
        _fixedInflationContract = msg.sender;
    }

    function data() view public override returns(address fixedInflationContract, address host) {
        return(_fixedInflationContract, _host);
    }

    function setHost(address host) public virtual override hostOnly {
        _host = host;
    }

    function setActive(bool _active) public override virtual hostOnly {
        active = _active;
    }

    function receiveTokens(address[] memory tokenAddresses, uint256[] memory transferAmounts, uint256[] memory amountsToMint) public override fixedInflationOnly {
        IMVDProxy(IDoubleProxy(_host).proxy()).submit(FUNCTIONALITY_NAME, abi.encode(address(0), 0, tokenAddresses, transferAmounts, amountsToMint, _fixedInflationContract));
    }

    function setEntry(FixedInflationEntry memory newEntry, FixedInflationOperation[] memory newOperations) public override hostOnly {
        IFixedInflation(_fixedInflationContract).setEntry(newEntry, newOperations);
    }

    function flushBack(address[] memory tokenAddresses) public override hostOnly {
        IFixedInflation(_fixedInflationContract).flushBack(tokenAddresses);
        address walletAddress = _getDFOWallet();
        for(uint256 i = 0; i < tokenAddresses.length; i++) {
            _transferTo(tokenAddresses[i], walletAddress, _balanceOf(tokenAddresses[i]));
        }
    }

    function deactivationByFailure() public override fixedInflationOnly {
        active = false;
    }

    function _getFunctionalityAddress() private view returns(address functionalityAddress) {
        (functionalityAddress,,,,) = IMVDFunctionalitiesManager(IMVDProxy(IDoubleProxy(_host).proxy()).getMVDFunctionalitiesManagerAddress()).getFunctionalityData(FUNCTIONALITY_NAME);
    }

    function _getDFOWallet() private view returns(address) {
        return IMVDProxy(IDoubleProxy(_host).proxy()).getMVDWalletAddress();
    }

    function _isFromDFO(address sender) private view returns(bool) {
        return IMVDFunctionalitiesManager(IMVDProxy(IDoubleProxy(_host).proxy()).getMVDFunctionalitiesManagerAddress()).isAuthorizedFunctionality(sender);
    }

    function _balanceOf(address tokenAddress) private view returns (uint256) {
        if(tokenAddress == address(0)) {
            return address(this).balance;
        }
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function _transferTo(address erc20TokenAddress, address to, uint256 value) private {
        if(value == 0) {
            return;
        }
        if(erc20TokenAddress == address(0)) {
            payable(to).transfer(value);
            return;
        }
        _safeTransfer(erc20TokenAddress, to, value);
    }

    function _safeTransfer(address erc20TokenAddress, address to, uint256 value) private {
        bytes memory returnData = _call(erc20TokenAddress, abi.encodeWithSelector(IERC20(erc20TokenAddress).transfer.selector, to, value));
        require(returnData.length == 0 || abi.decode(returnData, (bool)), 'TRANSFER_FAILED');
    }

    function _call(address location, bytes memory payload) private returns(bytes memory returnData) {
        assembly {
            let result := call(gas(), location, 0, add(payload, 0x20), mload(payload), 0, 0)
            let size := returndatasize()
            returnData := mload(0x40)
            mstore(returnData, size)
            let returnDataPayloadStart := add(returnData, 0x20)
            returndatacopy(returnDataPayloadStart, 0, size)
            mstore(0x40, add(returnDataPayloadStart, size))
            switch result case 0 {revert(returnDataPayloadStart, size)}
        }
    }
}