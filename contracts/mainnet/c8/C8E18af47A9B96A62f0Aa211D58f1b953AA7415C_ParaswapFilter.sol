// Copyright (C) 2021  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;

interface IAuthoriser {
    function isAuthorised(address _sender, address _spender, address _to, bytes calldata _data) external view returns (bool);
    function areAuthorised(
        address _spender,
        address[] calldata _spenders,
        address[] calldata _to,
        bytes[] calldata _data
    )
        external
        view
        returns (bool);
}

// Copyright (C) 2021  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;

import "./IFilter.sol";

abstract contract BaseFilter is IFilter {
    function getMethod(bytes memory _data) internal pure returns (bytes4 method) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            method := mload(add(_data, 0x20))
        }
    }
}

// Copyright (C) 2021  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;

interface IFilter {
    function isValid(address _wallet, address _spender, address _to, bytes calldata _data) external view returns (bool valid);
}

// Copyright (C) 2021  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;

import "./BaseFilter.sol";
import "../IAuthoriser.sol";
import "../../modules/common/Utils.sol";

interface IUniswapV1Factory {
    function getExchange(address token) external view returns (address);
}

interface IParaswapUniswapProxy {
    function UNISWAP_FACTORY() external view returns (address);
    function UNISWAP_INIT_CODE() external view returns (bytes32);
    function WETH() external view returns (address);
}

interface IParaswap {
    struct Route {
        address payable exchange;
        address targetExchange;
        uint256 percent;
        bytes payload;
        uint256 networkFee;
    }

    struct Path {
        address to;
        uint256 totalNetworkFee;
        Route[] routes;
    }

    struct SellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        string referrer;
        bool useReduxToken;
        Path[] path;
    }

    struct MegaSwapPath {
        uint256 fromAmountPercent;
        Path[] path;
    }

    struct MegaSwapSellData {
        address fromToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 expectedAmount;
        address payable beneficiary;
        string referrer;
        bool useReduxToken;
        MegaSwapPath[] path;
    }

    struct UniswapV2Data {
        address[] path;
    }

    struct ZeroExV2Order {
        address makerAddress;
        address takerAddress;
        address feeRecipientAddress;
        address senderAddress;
        uint256 makerAssetAmount;
        uint256 takerAssetAmount;
        uint256 makerFee;
        uint256 takerFee;
        uint256 expirationTimeSeconds;
        uint256 salt;
        bytes makerAssetData;
        bytes takerAssetData;
    }

    struct ZeroExV2Data {
        ZeroExV2Order[] orders;
        bytes[] signatures;
    }

    struct ZeroExV4Order {
        address makerToken;
        address takerToken;
        uint128 makerAmount;
        uint128 takerAmount;
        address maker;
        address taker;
        address txOrigin;
        bytes32 pool;
        uint64 expiry;
        uint256 salt;
    }

    enum ZeroExV4SignatureType {
        ILLEGAL,
        INVALID,
        EIP712,
        ETHSIGN
    }

    struct ZeroExV4Signature {
        ZeroExV4SignatureType signatureType;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct ZeroExV4Data {
        ZeroExV4Order order;
        ZeroExV4Signature signature;
    }

    function getUniswapProxy() external view returns (address);
}

contract ParaswapFilter is BaseFilter {

    bytes4 constant internal MULTISWAP = bytes4(keccak256(
        "multiSwap((address,uint256,uint256,uint256,address,string,bool,(address,uint256,(address,address,uint256,bytes,uint256)[])[]))"
    ));
    bytes4 constant internal SIMPLESWAP = bytes4(keccak256(
        "simpleSwap(address,address,uint256,uint256,uint256,address[],bytes,uint256[],uint256[],address,string,bool)"
    ));
    bytes4 constant internal SWAP_ON_UNI = bytes4(keccak256(
        "swapOnUniswap(uint256,uint256,address[],uint8)"
    ));
    bytes4 constant internal SWAP_ON_UNI_FORK = bytes4(keccak256(
        "swapOnUniswapFork(address,bytes32,uint256,uint256,address[],uint8)"
    ));
    bytes4 constant internal MEGASWAP = bytes4(keccak256(
        "megaSwap((address,uint256,uint256,uint256,address,string,bool,(uint256,(address,uint256,(address,address,uint256,bytes,uint256)[])[])[]))"
    ));

    address constant internal ETH_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // The token price registry
    address public immutable tokenRegistry;
    // Paraswap entrypoint
    address public immutable augustus;
    // Supported Paraswap targetExchanges
    mapping(address => bool) public targetExchanges;
    // Supported ParaswapPool market makers
    mapping(address => bool) public marketMakers;
    // The supported adapters
    address public immutable uniV1Adapter;
    address public immutable uniV2Adapter;
    address public immutable sushiswapAdapter;
    address public immutable linkswapAdapter;
    address public immutable defiswapAdapter;
    address public immutable zeroExV2Adapter;
    address public immutable zeroExV4Adapter;
    // The Dapp registry (used to authorise simpleSwap())
    IAuthoriser public immutable authoriser;
    // Uniswap Proxy used by Paraswap's AugustusSwapper contract
    address public immutable uniswapProxy;
    // Whether the uniswap proxy has been changed -> needs manual update
    bool public isValidUniswapProxy = true;
    // WETH address
    address public immutable weth;

    // Supported Uniswap Fork (factory, initcode) couples.
    // Note that a `mapping(address => bytes32) public supportedInitCodes;` would be cleaner
    // but would cost one storage read to authorise each uni fork swap.
    address public immutable uniFactory; // uniswap
    address public immutable uniForkFactory1; // sushiswap
    address public immutable uniForkFactory2; // linkswap
    address public immutable uniForkFactory3; // defiswap
    bytes32 public immutable uniInitCode; // uniswap
    bytes32 public immutable uniForkInitCode1; // sushiswap
    bytes32 public immutable uniForkInitCode2; // linkswap
    bytes32 public immutable uniForkInitCode3; // defiswap

    constructor(
        address _tokenRegistry,
        IAuthoriser _authoriser,
        address _augustus,
        address _uniswapProxy,
        address[3] memory _uniFactories,
        bytes32[3] memory _uniInitCodes,
        address[7] memory _adapters,
        address[] memory _targetExchanges,
        address[] memory _marketMakers
    ) {
        tokenRegistry = _tokenRegistry;
        authoriser = _authoriser;
        augustus = _augustus;
        uniswapProxy = _uniswapProxy;
        weth = IParaswapUniswapProxy(_uniswapProxy).WETH();
        uniFactory = IParaswapUniswapProxy(_uniswapProxy).UNISWAP_FACTORY();
        uniInitCode = IParaswapUniswapProxy(_uniswapProxy).UNISWAP_INIT_CODE();
        uniForkFactory1 = _uniFactories[0];
        uniForkFactory2 = _uniFactories[1];
        uniForkFactory3 = _uniFactories[2];
        uniForkInitCode1 = _uniInitCodes[0];
        uniForkInitCode2 = _uniInitCodes[1];
        uniForkInitCode3 = _uniInitCodes[2];
        uniV1Adapter = _adapters[0];
        uniV2Adapter = _adapters[1];
        sushiswapAdapter = _adapters[2];
        linkswapAdapter = _adapters[3];
        defiswapAdapter = _adapters[4];
        zeroExV2Adapter = _adapters[5];
        zeroExV4Adapter = _adapters[6];
        for(uint i = 0; i < _targetExchanges.length; i++) {
            targetExchanges[_targetExchanges[i]] = true;
        }
        for(uint i = 0; i < _marketMakers.length; i++) {
            marketMakers[_marketMakers[i]] = true;
        }
    }

    function updateIsValidUniswapProxy() external {
        isValidUniswapProxy = (uniswapProxy == IParaswap(augustus).getUniswapProxy());
    }

    function isValid(address _wallet, address /*_spender*/, address _to, bytes calldata _data) external view override returns (bool valid) {
        // disable ETH transfer & unsupported Paraswap entrypoints
        if (_data.length < 4 || _to != augustus) {
            return false;
        }
        bytes4 methodId = getMethod(_data);
        if(methodId == MULTISWAP) {
            return isValidMultiSwap(_wallet, _data);
        } 
        if(methodId == SIMPLESWAP) {
            return isValidSimpleSwap(_wallet, _to, _data);
        }
        if(methodId == SWAP_ON_UNI) {
            return isValidUniSwap(_data);
        }
        if(methodId == SWAP_ON_UNI_FORK) {
            return isValidUniForkSwap(_data);
        }
        if(methodId == MEGASWAP) {
            return isValidMegaSwap(_wallet, _data);
        }
        return false;
    }

    function isValidMultiSwap(address _wallet, bytes calldata _data) internal view returns (bool) {
        (IParaswap.SellData memory sell) = abi.decode(_data[4:], (IParaswap.SellData));
        return hasValidBeneficiary(_wallet, sell.beneficiary) && hasValidPath(sell.fromToken, sell.path);
    }

    function isValidSimpleSwap(address _wallet, address _augustus, bytes calldata _data) internal view returns (bool) {
        (,address toToken,, address[] memory callees,, uint256[] memory startIndexes,, address beneficiary) 
            = abi.decode(_data[4:], (address, address, uint256[3],address[],bytes,uint256[],uint256[],address));
        return hasValidBeneficiary(_wallet, beneficiary) &&
            hasTradableToken(toToken) &&
            hasAuthorisedCallees(_augustus, callees, startIndexes, _data);
    }

    function isValidUniSwap(bytes calldata _data) internal view returns (bool) {
        if(!isValidUniswapProxy) {
            return false;
        }
        (, address[] memory path) = abi.decode(_data[4:], (uint256[2], address[]));
        return hasValidUniV2Path(path, uniFactory, uniInitCode);
    }

    function isValidUniForkSwap(bytes calldata _data) internal view returns (bool) {
        if(!isValidUniswapProxy) {
            return false;
        }
        (address factory, bytes32 initCode,, address[] memory path) = abi.decode(_data[4:], (address, bytes32, uint256[2], address[]));
        return factory != address(0) && initCode != bytes32(0) && (
            (factory == uniForkFactory1 && initCode == uniForkInitCode1 && hasValidUniV2Path(path, uniForkFactory1, uniForkInitCode1)) ||
            (factory == uniForkFactory2 && initCode == uniForkInitCode2 && hasValidUniV2Path(path, uniForkFactory2, uniForkInitCode2)) ||
            (factory == uniForkFactory3 && initCode == uniForkInitCode3 && hasValidUniV2Path(path, uniForkFactory3, uniForkInitCode3))
        );
    }

    function isValidMegaSwap(address _wallet, bytes calldata _data) internal view returns (bool) {
        (IParaswap.MegaSwapSellData memory sell) = abi.decode(_data[4:], (IParaswap.MegaSwapSellData));
        return hasValidBeneficiary(_wallet, sell.beneficiary) && hasValidMegaPath(sell.fromToken, sell.path);
    }

    function hasAuthorisedCallees(
        address _augustus,
        address[] memory _callees,
        uint256[] memory _startIndexes,
        bytes calldata _data
    )
        internal
        view
        returns (bool)
    {
        // _data = {sig:4}{six params:192}{exchangeDataOffset:32}{...}
        // we add 4+32=36 to the offset to skip the method sig and the size of the exchangeData array
        uint256 exchangeDataOffset = 36 + abi.decode(_data[196:228], (uint256)); 
        address[] memory spenders = new address[](_callees.length);
        bytes[] memory allData = new bytes[](_callees.length);
        for(uint256 i = 0; i < _callees.length; i++) {
            bytes calldata slicedExchangeData = _data[exchangeDataOffset+_startIndexes[i] : exchangeDataOffset+_startIndexes[i+1]];
            allData[i] = slicedExchangeData;
            spenders[i] = Utils.recoverSpender(_callees[i], slicedExchangeData);
        }
        return authoriser.areAuthorised(_augustus, spenders, _callees, allData);
    }

    function hasValidBeneficiary(address _wallet, address _beneficiary) internal pure returns (bool) {
        return (_beneficiary == address(0) || _beneficiary == _wallet);
    }

    function hasValidUniV2Path(address[] memory _path, address _factory, bytes32 _initCode) internal view returns (bool) {
        address[] memory lpTokens = new address[](_path.length - 1);
        for(uint i = 0; i < lpTokens.length; i++) {
            lpTokens[i] = pairFor(_path[i], _path[i+1], _factory, _initCode);
        }
        return hasTradableTokens(lpTokens);
    }

    function pairFor(address _tokenA, address _tokenB, address _factory, bytes32 _initCode) internal view returns (address) {
        (address tokenA, address tokenB) = (_tokenA == ETH_TOKEN ? weth : _tokenA, _tokenB == ETH_TOKEN ? weth : _tokenB);
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        return(address(uint160(uint(keccak256(abi.encodePacked(
            hex"ff",
            _factory,
            keccak256(abi.encodePacked(token0, token1)),
            _initCode
        ))))));
    }

    function hasTradableToken(address _destToken) internal view returns (bool) {
        if(_destToken == ETH_TOKEN) {
            return true;
        }
        (bool success, bytes memory res) = tokenRegistry.staticcall(abi.encodeWithSignature("isTokenTradable(address)", _destToken));
        return success && abi.decode(res, (bool));
    }

    function hasTradableTokens(address[] memory _tokens) internal view returns (bool) {
        (bool success, bytes memory res) = tokenRegistry.staticcall(abi.encodeWithSignature("areTokensTradable(address[])", _tokens));
        return success && abi.decode(res, (bool));
    }

    function hasValidPath(address _fromToken, IParaswap.Path[] memory _path) internal view returns (bool) {
        for (uint i = 0; i < _path.length; i++) {
            for (uint j = 0; j < _path[i].routes.length; j++) {
                if(!hasValidRoute(_path[i].routes[j], (i == 0) ? _fromToken : _path[i-1].to, _path[i].to)) {
                    return false;
                }
            }
        }
        return true;
    }

    function hasValidRoute(IParaswap.Route memory _route, address _fromToken, address _toToken) internal view returns (bool) {
        if(_route.targetExchange != address(0) && !targetExchanges[_route.targetExchange]) {
            return false;
        }
        if(_route.exchange == uniV2Adapter) { 
            return hasValidUniV2Route(_route.payload, uniFactory, uniInitCode);
        } 
        if(_route.exchange == sushiswapAdapter) { 
            return hasValidUniV2Route(_route.payload, uniForkFactory1, uniForkInitCode1);
        }
        if(_route.exchange == zeroExV4Adapter) { 
            return hasValidZeroExV4Route(_route.payload);
        }
        if(_route.exchange == zeroExV2Adapter) { 
            return hasValidZeroExV2Route(_route.payload);
        }
        if(_route.exchange == linkswapAdapter) { 
            return hasValidUniV2Route(_route.payload, uniForkFactory2, uniForkInitCode2);
        }
        if(_route.exchange == defiswapAdapter) { 
            return hasValidUniV2Route(_route.payload, uniForkFactory3, uniForkInitCode3);
        }
        if(_route.exchange == uniV1Adapter) { 
            return hasValidUniV1Route(_route.targetExchange, _fromToken, _toToken);
        }
        return false;  
    }

    function hasValidUniV2Route(bytes memory _payload, address _factory, bytes32 _initCode) internal view returns (bool) {
        IParaswap.UniswapV2Data memory data = abi.decode(_payload, (IParaswap.UniswapV2Data));
        return hasValidUniV2Path(data.path, _factory, _initCode);
    }

    function hasValidUniV1Route(address _uniV1Factory, address _fromToken, address _toToken) internal view returns (bool) {
        address pool = IUniswapV1Factory(_uniV1Factory).getExchange(_fromToken == ETH_TOKEN ? _toToken : _fromToken);
        return hasTradableToken(pool);
    }

    function hasValidZeroExV4Route(bytes memory _payload) internal view returns (bool) {
        IParaswap.ZeroExV4Data memory data = abi.decode(_payload, (IParaswap.ZeroExV4Data));
        return marketMakers[data.order.maker];
    }

    function hasValidZeroExV2Route(bytes memory _payload) internal view returns (bool) {
        IParaswap.ZeroExV2Data memory data = abi.decode(_payload, (IParaswap.ZeroExV2Data));
        for(uint i = 0; i < data.orders.length; i++) {
            if(!marketMakers[data.orders[i].makerAddress]) {
                return false;
            }
        }
        return true;
    }

    function hasValidMegaPath(address _fromToken, IParaswap.MegaSwapPath[] memory _megaPath) internal view returns (bool) {
        for(uint i = 0; i < _megaPath.length; i++) {
            if(!hasValidPath(_fromToken, _megaPath[i].path)) {
                return false;
            }
        }
        return true;
    }
}

// Copyright (C) 2020  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.3;

/**
 * @title Utils
 * @notice Common utility methods used by modules.
 */
library Utils {

    // ERC20, ERC721 & ERC1155 transfers & approvals
    bytes4 private constant ERC20_TRANSFER = bytes4(keccak256("transfer(address,uint256)"));
    bytes4 private constant ERC20_APPROVE = bytes4(keccak256("approve(address,uint256)"));
    bytes4 private constant ERC721_SET_APPROVAL_FOR_ALL = bytes4(keccak256("setApprovalForAll(address,bool)"));
    bytes4 private constant ERC721_TRANSFER_FROM = bytes4(keccak256("transferFrom(address,address,uint256)"));
    bytes4 private constant ERC721_SAFE_TRANSFER_FROM = bytes4(keccak256("safeTransferFrom(address,address,uint256)"));
    bytes4 private constant ERC721_SAFE_TRANSFER_FROM_BYTES = bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));
    bytes4 private constant ERC1155_SAFE_TRANSFER_FROM = bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)"));

    bytes4 private constant OWNER_SIG = 0x8da5cb5b;
    /**
    * @notice Helper method to recover the signer at a given position from a list of concatenated signatures.
    * @param _signedHash The signed hash
    * @param _signatures The concatenated signatures.
    * @param _index The index of the signature to recover.
    */
    function recoverSigner(bytes32 _signedHash, bytes memory _signatures, uint _index) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(_signatures, add(0x20,mul(0x41,_index))))
            s := mload(add(_signatures, add(0x40,mul(0x41,_index))))
            v := and(mload(add(_signatures, add(0x41,mul(0x41,_index)))), 0xff)
        }
        require(v == 27 || v == 28, "Utils: bad v value in signature");

        address recoveredAddress = ecrecover(_signedHash, v, r, s);
        require(recoveredAddress != address(0), "Utils: ecrecover returned 0");
        return recoveredAddress;
    }

    /**
    * @notice Helper method to recover the spender from a contract call. 
    * The method returns the contract unless the call is to a standard method of a ERC20/ERC721/ERC1155 token
    * in which case the spender is recovered from the data.
    * @param _to The target contract.
    * @param _data The data payload.
    */
    function recoverSpender(address _to, bytes memory _data) internal pure returns (address spender) {
        if(_data.length >= 68) {
            bytes4 methodId;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                methodId := mload(add(_data, 0x20))
            }
            if(
                methodId == ERC20_TRANSFER ||
                methodId == ERC20_APPROVE ||
                methodId == ERC721_SET_APPROVAL_FOR_ALL) 
            {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    spender := mload(add(_data, 0x24))
                }
                return spender;
            }
            if(
                methodId == ERC721_TRANSFER_FROM ||
                methodId == ERC721_SAFE_TRANSFER_FROM ||
                methodId == ERC721_SAFE_TRANSFER_FROM_BYTES ||
                methodId == ERC1155_SAFE_TRANSFER_FROM)
            {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    spender := mload(add(_data, 0x44))
                }
                return spender;
            }
        }

        spender = _to;
    }

    /**
    * @notice Helper method to parse data and extract the method signature.
    */
    function functionPrefix(bytes memory _data) internal pure returns (bytes4 prefix) {
        require(_data.length >= 4, "Utils: Invalid functionPrefix");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            prefix := mload(add(_data, 0x20))
        }
    }

    /**
    * @notice Checks if an address is a contract.
    * @param _addr The address.
    */
    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    /**
    * @notice Checks if an address is a guardian or an account authorised to sign on behalf of a smart-contract guardian
    * given a list of guardians.
    * @param _guardians the list of guardians
    * @param _guardian the address to test
    * @return true and the list of guardians minus the found guardian upon success, false and the original list of guardians if not found.
    */
    function isGuardianOrGuardianSigner(address[] memory _guardians, address _guardian) internal view returns (bool, address[] memory) {
        if (_guardians.length == 0 || _guardian == address(0)) {
            return (false, _guardians);
        }
        bool isFound = false;
        address[] memory updatedGuardians = new address[](_guardians.length - 1);
        uint256 index = 0;
        for (uint256 i = 0; i < _guardians.length; i++) {
            if (!isFound) {
                // check if _guardian is an account guardian
                if (_guardian == _guardians[i]) {
                    isFound = true;
                    continue;
                }
                // check if _guardian is the owner of a smart contract guardian
                if (isContract(_guardians[i]) && isGuardianOwner(_guardians[i], _guardian)) {
                    isFound = true;
                    continue;
                }
            }
            if (index < updatedGuardians.length) {
                updatedGuardians[index] = _guardians[i];
                index++;
            }
        }
        return isFound ? (true, updatedGuardians) : (false, _guardians);
    }

    /**
    * @notice Checks if an address is the owner of a guardian contract.
    * The method does not revert if the call to the owner() method consumes more then 25000 gas.
    * @param _guardian The guardian contract
    * @param _owner The owner to verify.
    */
    function isGuardianOwner(address _guardian, address _owner) internal view returns (bool) {
        address owner = address(0);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr,OWNER_SIG)
            let result := staticcall(25000, _guardian, ptr, 0x20, ptr, 0x20)
            if eq(result, 1) {
                owner := mload(ptr)
            }
        }
        return owner == _owner;
    }

    /**
    * @notice Returns ceil(a / b).
    */
    function ceil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        if (a % b == 0) {
            return c;
        } else {
            return c + 1;
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 999
  },
  "evmVersion": "istanbul",
  "libraries": {
    "": {}
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}