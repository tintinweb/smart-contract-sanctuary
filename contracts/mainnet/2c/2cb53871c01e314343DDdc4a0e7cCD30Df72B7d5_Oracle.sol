/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;




interface IERC20 {
     function decimals() external view returns (uint8);
}

// Part: OpenZeppelin/[email protected]/Context

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Oracle is Ownable {
    address[] private _calculations;
    address public usdcAddress;
    mapping(address => address) public tokenAliases;

    event TokenAliasAdded(address tokenAddress, address tokenAliasAddress);
    event TokenAliasRemoved(address tokenAddress);

    struct TokenAlias {
        address tokenAddress;
        address tokenAliasAddress;
    }

    constructor(address _usdcAddress) public 
    {
        usdcAddress = _usdcAddress;
    }

    function setCalculations(address[] memory calculationAddresses)
        external
        onlyOwner
    {
        _calculations = calculationAddresses;
    }

    function calculations() external view returns (address[] memory) {
        return (_calculations);
    }

    function addTokenAlias(address tokenAddress, address tokenAliasAddress)
        public
        onlyOwner
    {
        tokenAliases[tokenAddress] = tokenAliasAddress;
        emit TokenAliasAdded(tokenAddress, tokenAliasAddress);
    }

    function addTokenAliases(TokenAlias[] memory _tokenAliases)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _tokenAliases.length; i++) {
            addTokenAlias(
                _tokenAliases[i].tokenAddress,
                _tokenAliases[i].tokenAliasAddress
            );
        }
    }

    function removeTokenAlias(address tokenAddress) public onlyOwner {
        delete tokenAliases[tokenAddress];
        emit TokenAliasRemoved(tokenAddress);
    }

    function getNormalizedValueUsdc(
        address tokenAddress,
        uint256 amount,
        uint256 priceUsdc
    ) public view returns (uint256) {
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenDecimals = token.decimals();

        uint256 usdcDecimals = 6;
        uint256 decimalsAdjustment;
        if (tokenDecimals >= usdcDecimals) {
            decimalsAdjustment = tokenDecimals - usdcDecimals;
        } else {
            decimalsAdjustment = usdcDecimals - tokenDecimals;
        }
        uint256 value;
        if (decimalsAdjustment > 0) {
            value =
                (amount * priceUsdc * (10**decimalsAdjustment)) /
                10**(decimalsAdjustment + tokenDecimals);
        } else {
            value = (amount * priceUsdc) / 10**usdcDecimals;
        }
        return value;
    }

    function getNormalizedValueUsdc(address tokenAddress, uint256 amount)
        external
        view
        returns (uint256)
    {
        uint256 priceUsdc = getPriceUsdcRecommended(tokenAddress);
        return getNormalizedValueUsdc(tokenAddress, amount, priceUsdc);
    }

    function getPriceUsdcRecommended(address tokenAddress)
        public
        view
        returns (uint256)
    {
        address tokenAddressAlias = tokenAliases[tokenAddress];
        address tokenToQuery = tokenAddress;
        if (tokenAddressAlias != address(0)) {
            tokenToQuery = tokenAddressAlias;
        }
        (bool success, bytes memory data) =
            address(this).staticcall(
                abi.encodeWithSignature("getPriceUsdc(address)", tokenToQuery)
            );
        if (success) {
            return abi.decode(data, (uint256));
        }
        return 0;
    }

    fallback() external {
        for (uint256 i = 0; i < _calculations.length; i++) {
            address calculation = _calculations[i];
            assembly {
                let _target := calculation
                calldatacopy(0, 0, calldatasize())
                let success := staticcall(
                    gas(),
                    _target,
                    0,
                    calldatasize(),
                    0,
                    0
                )
                returndatacopy(0, 0, returndatasize())
                if success {
                    return(0, returndatasize())
                }
            }
        }
        revert("Oracle: Fallback proxy failed to return data");
    }
}