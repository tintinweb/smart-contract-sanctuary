/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

// File: contracts\fixed-inflation\FixedInflationData.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

struct FixedInflationEntryConfiguration {
    bool add;
    bool remove;
    FixedInflationEntry data;
}

struct FixedInflationEntry {
    uint256 lastBlock;
    bytes32 id;
    string name;
    uint256 blockInterval;
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

    function setEntries(FixedInflationEntryConfiguration[] memory newEntries, FixedInflationOperation[][] memory operationSets) external;
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

    function setEntries(FixedInflationEntryConfiguration[] memory newEntries, FixedInflationOperation[][] memory operationSets) external;
}

// File: contracts\fixed-inflation\DFOBasedFixedInflationExtension.sol

//SPDX_License_Identifier: MIT
pragma solidity ^0.7.6;
//pragma abicoder v2;





contract DFOBasedFixedInflationExtension is IFixedInflationExtension {

    string private constant FUNCTIONALITY_NAME = "manageFixedInflation";

    address private _host;

    address private _fixedInflationContract;

    modifier fixedInflationOnly() {
        require(_fixedInflationContract == msg.sender, "Unauthorized");
        _;
    }

    modifier hostOnly() {
        require(_isFromDFO(msg.sender), "Unauthorized");
        _;
    }

    function init(address doubleProxyAddress) override public {
        require(_host == address(0), "Already init");
        require(doubleProxyAddress != address(0), "blank host");
        _host = doubleProxyAddress;
        _fixedInflationContract = msg.sender;
    }

    function data() view public override returns(address fixedInflationContract, address host) {
        return(_fixedInflationContract, _host);
    }

    function setHost(address host) public virtual override hostOnly {
        _host = host;
    }

    function receiveTokens(address[] memory tokenAddresses, uint256[] memory transferAmounts, uint256[] memory amountsToMint) public override fixedInflationOnly {
        IMVDProxy(IDoubleProxy(_host).proxy()).submit(FUNCTIONALITY_NAME, abi.encode(address(0), 0, tokenAddresses, transferAmounts, amountsToMint, _fixedInflationContract));
    }

    function setEntries(FixedInflationEntryConfiguration[] memory newEntries, FixedInflationOperation[][] memory operationSets) public override hostOnly {
        IFixedInflation(_fixedInflationContract).setEntries(newEntries, operationSets);
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
}