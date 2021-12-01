//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Helper } from "./helpers.sol";

import { 
    InstaFlashloanAggregatorInterface
} from "./interfaces.sol";

contract FlashResolverPolygon is Helper {
    function getRoutesInfo() public view returns (uint16[] memory routes_, uint256[] memory fees_) {
        routes_ = flashloanAggregator.getRoutes();
        fees_ = new uint256[](routes_.length);
        for(uint256 i = 0; i < routes_.length; i++) {
            fees_[i] = flashloanAggregator.calculateFeeBPS(routes_[i]);
        }
    }

    function getBestRoutes(address[] memory _tokens, uint256[] memory _amounts) public view returns (uint16[] memory, uint256) {
        require(_tokens.length == _amounts.length, "array-lengths-not-same");

        (_tokens, _amounts) = bubbleSort(_tokens, _amounts);
        validateTokens(_tokens);
        
        uint16[] memory bRoutes_;
        uint256 feeBPS_;
        uint16[] memory routes_ = flashloanAggregator.getRoutes();
        uint16[] memory routesWithAvailability_ = getRoutesWithAvailability(routes_, _tokens, _amounts);
        uint16 j = 0;
        bRoutes_ = new uint16[](routes_.length);
        feeBPS_ = type(uint256).max;
        for(uint256 i = 0; i < routesWithAvailability_.length; i++) {
            if(routesWithAvailability_[i] != 0) {
                uint routeFeeBPS_ = flashloanAggregator.calculateFeeBPS(routesWithAvailability_[i]);
                if(feeBPS_ > routeFeeBPS_) {
                    feeBPS_ = routeFeeBPS_;
                    bRoutes_[0] = routesWithAvailability_[i];
                    j=1;
                } else if (feeBPS_ == routeFeeBPS_) {
                    bRoutes_[j] = routesWithAvailability_[i];
                    j++;
                }
            } 
        }
        uint16[] memory bestRoutes_ = new uint16[](j);
        for(uint256 i = 0; i < j ; i++) {
            bestRoutes_[i] = bRoutes_[i];
        }
        return (bestRoutes_, feeBPS_);
    }

    function getData(address[] memory _tokens, uint256[] memory _amounts) public view returns (uint16[] memory routes_, uint256[] memory fees_, uint16[] memory bestRoutes_, uint256 bestFee_) {
        (routes_, fees_) = getRoutesInfo();
        (bestRoutes_, bestFee_) = getBestRoutes(_tokens, _amounts);
        return (routes_, fees_, bestRoutes_, bestFee_);
    }
}

contract InstaFlashloanResolverPolygon is FlashResolverPolygon {
    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Variables} from "./variables.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Helper is Variables {
    function getAaveAvailability(address[] memory  _tokens, uint256[] memory  _amounts) internal view returns (bool) {
        for(uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            (,,,,,,,,bool isActive,) = aaveProtocolDataProvider.getReserveConfigurationData(_tokens[i]);
            (address aTokenAddr,,) = aaveProtocolDataProvider.getReserveTokensAddresses(_tokens[i]);
            if(isActive == false) return false;
            if(token_.balanceOf(aTokenAddr) < _amounts[i]) return false;
        }
        return true;
    }

    function getBalancerAvailability(address[] memory _tokens, uint256[] memory _amounts) internal view returns (bool) {
        for(uint256 i = 0; i < _tokens.length; i++) {
            IERC20 token_ = IERC20(_tokens[i]);
            if (token_.balanceOf(balancerLendingAddr) < _amounts[i]) {
                return false;
            }
        }
        return true;
    }

    function getRoutesWithAvailability(uint16[] memory _routes, address[] memory _tokens, uint256[] memory _amounts) internal view returns (uint16[] memory) {
        uint16[] memory routesWithAvailability_ = new uint16[](7);
        uint j = 0;
        for(uint256 i = 0; i < _routes.length; i++) {
            if (_routes[i] == 1 || _routes[i] == 7) {
                if(getAaveAvailability(_tokens, _amounts)) {
                    routesWithAvailability_[j] = _routes[i];
                    j++;
                }
            } else if (_routes[i] == 5) {
                if(getBalancerAvailability(_tokens, _amounts)) {
                    routesWithAvailability_[j] = _routes[i];
                    j++;
                }
            } else {
                require(false, "invalid-route");
            }
        }
        return routesWithAvailability_;
    }

    function bubbleSort(address[] memory _tokens, uint256[] memory _amounts) internal pure returns (address[] memory, uint256[] memory) {
        for (uint256 i = 0; i < _tokens.length - 1; i++) {
            for( uint256 j = 0; j < _tokens.length - i - 1 ; j++) {
                if(_tokens[j] > _tokens[j+1]) {
                    (_tokens[j], _tokens[j+1], _amounts[j], _amounts[j+1]) = (_tokens[j+1], _tokens[j], _amounts[j+1], _amounts[j]);
                }
            }
        }
        return (_tokens, _amounts);
    }

    function validateTokens(address[] memory _tokens) internal pure {
        for (uint i = 0; i < _tokens.length - 1; i++) {
            require(_tokens[i] != _tokens[i+1], "non-unique-tokens");
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface InstaFlashloanAggregatorInterface {
    function getRoutes() external pure returns (uint16[] memory);
    function calculateFeeBPS(uint256 _route) external view returns (uint256);
    function tokenToCToken(address) external view returns (address);
}

interface IAaveProtocolDataProvider {
    function getReserveConfigurationData(address asset) external view returns (uint256, uint256, uint256, uint256, uint256, bool, bool, bool, bool, bool);
    function getReserveTokensAddresses(address asset) external view returns (address, address, address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import { 
    InstaFlashloanAggregatorInterface,
    IAaveProtocolDataProvider
} from "./interfaces.sol";

contract Variables {

    address public constant aaveLendingAddr = 0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf;
    address public constant aaveProtocolDataProviderAddr = 0x7551b5D2763519d4e37e8B81929D336De671d46d;
    IAaveProtocolDataProvider public constant aaveProtocolDataProvider = IAaveProtocolDataProvider(aaveProtocolDataProviderAddr);

    address public constant balancerLendingAddr = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

    address private flashloanAggregatorAddr = 0x56Daa5393d7d25Cb1d06F1E78FE0064b22111b54;
    InstaFlashloanAggregatorInterface internal flashloanAggregator = InstaFlashloanAggregatorInterface(flashloanAggregatorAddr);

}