/* Discussion:
 * //github.com/b-u-i-d-l/dfo-hub
 */
/* Description:
 * QuickScope - A simple DFO Microservice to easily swap Programmable Equities through Uniswap V2
 */
//SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

/**
 * @title QuickScope - A simple DFO Microservice to easily swap Programmable Equities through Uniswap V2
 * @dev This general-purpose microservice can be called only by authorized sender, which can be easily set
 * using the DFOhub StateHolder.
 */
contract QuickScopeMicroservice {

    string private _metadataLink;

    /**
     * @dev Microservice Constructor
     * @param metadataLink The IPFS location of the Metadata, saved in JSON Format
     */
    constructor(string memory metadataLink) {
        _metadataLink = metadataLink;
    }

    /**
     * @dev GET the metadataLink
     */
    function getMetadataLink() public view returns(string memory) {
        return _metadataLink;
    }

    /**
     * @dev The Microservice method start
     * It sets up the operator able to call the microservice
     */
    function onStart(address, address) public {
        IMVDProxy proxy = IMVDProxy(msg.sender);
        IStateHolder stateHolder = IStateHolder(proxy.getStateHolderAddress());
        address quickScopeOperator = 0xd6b6B5c0F41D77E41C33a8e2B8BACe8fdBf4eDef;
        stateHolder.setBool(string(abi.encode("quickScope.operator.", _toLowerCase(_toString(quickScopeOperator)))), true);
    }

    /**
     * @dev The Microservice method end
     * It avoids the operator able to call the microservice
     */
    function onStop(address) public {
        IMVDProxy proxy = IMVDProxy(msg.sender);
        IStateHolder stateHolder = IStateHolder(proxy.getStateHolderAddress());
        address quickScopeOperator = 0xd6b6B5c0F41D77E41C33a8e2B8BACe8fdBf4eDef;
        stateHolder.clear(string(abi.encode("quickScope.operator.", _toLowerCase(_toString(quickScopeOperator)))));
    }

    /**
     * @dev The microservice main method.
     * It transfers the desiderd tokens then swap it on UniswapV2, sending back again the gained tokens to the DFO.
     * @param sender The original msg.sender who called the DFO Proxy. It should be the operator authorized to perform the action.
     * @param uniswapV2RouterAddress The Uniswap V2 Router address useful to perform the operation
     * @param path The token path to be used to swap the token
     * @param amountIn The amount of passed token to be swapped
     * @param amountOutMin The output amount to be received, it can contain the slippage
     * @param deadline The swap deadline before to declare void this swap
     */
    function quickScope(address sender, uint256, address uniswapV2RouterAddress, address[] memory path, uint256 amountIn, uint256 amountOutMin, uint256 deadline) public {
        IMVDProxy proxy = IMVDProxy(msg.sender);
        IStateHolder stateHolder = IStateHolder(proxy.getStateHolderAddress());
        require(stateHolder.getBool(string(abi.encode("quickScope.operator.", _toLowerCase(_toString(sender))))), "Unauthorized Action!");
        address walletAddress = proxy.getMVDWalletAddress();
        proxy.transfer(address(this), amountIn, path[0]);
        _checkAllowance(path[0], amountIn, uniswapV2RouterAddress);
        IUniswapV2Router(uniswapV2RouterAddress).swapExactTokensForTokens(amountIn, amountOutMin, path, walletAddress, deadline);
        _flush(path, walletAddress);
    }

    function _checkAllowance(
        address tokenAddress,
        uint256 value,
        address spender
    ) private {
        IERC20 token = IERC20(tokenAddress);
        if (token.allowance(address(this), spender) <= value) {
            token.approve(spender, value);
        }
    }

    function _flush(address[] memory tokenAddresses, address receiver) private {
        for(uint256 i = 0; i < tokenAddresses.length; i++) {
            IERC20 token = IERC20(tokenAddresses[i]);
            uint256 balance = token.balanceOf(address(this));
            if(balance > 0) {
                token.transfer(receiver, balance);
            }
        }
        uint256 balance = address(this).balance;
        if(balance > 0) {
            payable(receiver).transfer(balance);
        }
    }

    function _toString(address _addr) private pure returns(string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }

    function _toLowerCase(string memory str) private pure returns(string memory) {
        bytes memory bStr = bytes(str);
        for (uint i = 0; i < bStr.length; i++) {
            bStr[i] = bStr[i] >= 0x41 && bStr[i] <= 0x5A ? bytes1(uint8(bStr[i]) + 0x20) : bStr[i];
        }
        return string(bStr);
    }
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IMVDProxy {
    function getStateHolderAddress() external view returns(address);
    function getMVDWalletAddress() external view returns (address);
    function transfer(address receiver, uint256 value, address token) external;
}

interface IMVDFunctionalitiesManager {
    function isAuthorizedFunctionality(address functionality) external view returns(bool);
}

interface IStateHolder {
    function clear(string calldata varName) external returns(string memory oldDataType, bytes memory oldVal);
    function setBool(string calldata varName, bool val) external returns(bool);
    function getBool(string calldata varName) external view returns (bool);
}