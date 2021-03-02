/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

/** This is the template of the Fixed Inflation Extension. You can edit as you whish.
 *  Just remember that the following methods are MANDATORY:
 *
 *  function active() public view returns (bool)
 *
 *  function receiveTokens(address[] memory tokenAddresses, uint256[] memory transferAmounts, uint256[] memory amountsToMint) public
 *
 *  function deactivationByFailure() public
 **/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

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

interface IERC20 {
    function totalSupply() external view returns(uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);
}

interface IERC20Mintable {
    function mint(address wallet, uint256 amount) external returns (bool);
    function burn(address wallet, uint256 amount) external returns (bool);
}

interface IFixedInflation {

    function setEntry(FixedInflationEntry memory entryData, FixedInflationOperation[] memory operations) external;

    function flushBack(address[] memory tokenAddresses) external;
}

contract FixedInflationExtension {

    address private _host;

    address private _fixedInflationContract;

    bool public active;

    modifier fixedInflationOnly() {
        require(_fixedInflationContract == msg.sender, "Unauthorized");
        _;
    }

    modifier hostOnly() {
        require(_host == msg.sender, "Unauthorized");
        _;
    }

    receive() external payable {
    }

    function init(address host) public {
        require(_host == address(0), "Already init");
        require((_host = host) != address(0), "blank host");
        _fixedInflationContract = msg.sender;
    }

    function setHost(address host) public virtual hostOnly {
        _host = host;
    }

    function data() view public returns(address fixedInflationContract, address host) {
        return(_fixedInflationContract, _host);
    }

    function setActive(bool _active) public virtual hostOnly {
        active = _active;
    }

    function receiveTokens(address[] memory tokenAddresses, uint256[] memory transferAmounts, uint256[] memory amountsToMint) public fixedInflationOnly {
        for(uint256 i = 0; i < tokenAddresses.length; i++) {
            if(transferAmounts[i] > 0) {
                if(tokenAddresses[i] == address(0)) {
                    (bool result,) = msg.sender.call{value:transferAmounts[i]}("");
                    require(result, "ETH transfer failed");
                    continue;
                }
                _safeTransfer(tokenAddresses[i], msg.sender, transferAmounts[i]);
            }
            if(amountsToMint[i] > 0) {
                _mintAndTransfer(tokenAddresses[i], msg.sender, amountsToMint[i]);
            }
        }
    }

    function setEntry(FixedInflationEntry memory newEntry, FixedInflationOperation[] memory newOperations) public hostOnly {
        IFixedInflation(_fixedInflationContract).setEntry(newEntry, newOperations);
    }

    function flushBack(address[] memory tokenAddresses) public hostOnly {
        IFixedInflation(_fixedInflationContract).flushBack(tokenAddresses);
    }

    function deactivationByFailure() public fixedInflationOnly {
        active = false;
    }

    function _mintAndTransfer(address erc20TokenAddress, address recipient, uint256 value) internal virtual {
        IERC20Mintable(erc20TokenAddress).mint(recipient, value);
    }

    function _safeTransfer(address erc20TokenAddress, address to, uint256 value) internal virtual {
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