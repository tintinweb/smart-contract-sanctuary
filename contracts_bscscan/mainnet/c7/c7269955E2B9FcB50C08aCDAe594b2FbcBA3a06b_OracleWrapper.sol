/**
 *Submitted for verification at BscScan.com on 2021-10-21
*/

// SPDX-License-Identifier: UNLICENCED

pragma solidity ^0.8.0;

interface Token {
    function decimals() external view returns(uint256);
}


interface uniswapInterface{
    function getAmountsOut(uint amountIn, address[] memory path)external view returns (uint[] memory amounts);
}

interface tellorInterface{
    function getLastNewValueById(uint _requestId) external view returns(uint,bool);
}


interface OracleInterface{
    function latestAnswer() external view returns (int256);
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @title CustomOwnable
 * @dev This contract has the owner address providing basic authorization control
 */
contract CustomOwnable is Context  {
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

    // Owner of the contract
    address private _owner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_msgSender() == owner(), "CustomOwnable: FORBIDDEN");
        _;
    }

    /**
     * @dev Tells the address of the owner
     * @return the address of the owner
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Sets a new owner address
     */
    function _setOwner(address newOwner) internal {
        _owner = newOwner;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "CustomOwnable: FORBIDDEN");
        emit OwnershipTransferred(owner(), newOwner);
        _setOwner(newOwner);
    }
}

contract OracleWrapper is CustomOwnable {
    
    bool isInitialized;
    address public tellerContractAddress;
    address public UniswapV2Router02;

    struct coinDetails {
        address oracleAddress;
        uint8   oracleType;
        uint88  id;
    }

    mapping(address => coinDetails) public coin;

   
   function initializeOracle(address _owner, address _tellerContractAddress, address _UniswapV2Router02) public {
        require(!isInitialized,"OracleWrapperV0 : Already initialized");
        tellerContractAddress = _tellerContractAddress;
        UniswapV2Router02 = _UniswapV2Router02;
        _setOwner(_owner);
        isInitialized = true;
    }
    
    function setOracleAddresses (address _coinAddress, address _oracleAddress, uint8 _oracleType, uint88 _id) public onlyOwner {
        require((_oracleType == 1) || (_oracleType == 2) || (_oracleType == 3), "OracleWrapperV0: Invalid oracleType");
        require(_coinAddress != address(0), "OracleWrapperV0 : Zero address");
        
        if (coin[_coinAddress].oracleType != 0) {
            require(coin[_coinAddress].oracleType == _oracleType, "OracleWrapperV0: Invalid Oracle type");
        }
        
        if (_oracleType == 3) {
            coin[_coinAddress].oracleType = _oracleType;
            coin[_oracleAddress].oracleType = _oracleType;
            coin[_coinAddress].oracleAddress = _oracleAddress;
            return;
        }
        
        coin[_coinAddress].oracleAddress = _oracleAddress;
        coin[_coinAddress].oracleType = _oracleType;
        
        if(_oracleType == 2) {
            coin[_coinAddress].id = _id;
        }
    }
  
    function getPrice(address _coinAddress, address pair) external view returns (uint256) {
        require((coin[_coinAddress].oracleType != uint8(0)), "OracleWrapperV0 : Coin not exists");
        
        uint256 price;

        if (coin[_coinAddress].oracleType  == 1) {
            OracleInterface oObj = OracleInterface(coin[_coinAddress].oracleAddress);
            return price = uint256(oObj.latestAnswer());
        } else if (coin[_coinAddress].oracleType == 2) {
            tellorInterface tObj = tellorInterface(tellerContractAddress);
            uint256 actualFiatPrice;
            bool statusTellor;
            (actualFiatPrice,statusTellor) = tObj.getLastNewValueById(coin[_coinAddress].id);
            return price = uint256(actualFiatPrice);
        } else if (coin[_coinAddress].oracleType == 3 && pair != address(0)) {
            uniswapInterface uObj = uniswapInterface(UniswapV2Router02);
            
            address[] memory path = new address[](2);
            path[0] = _coinAddress;
            path[1] = pair;
            uint[] memory values = uObj.getAmountsOut(10**(Token(_coinAddress).decimals()), path);

            return price = (values[1] * 100);
        }
        
        require(price != 0, "OracleWrapperV0: Price can't be zero");
        
        return 0;
        
    }
    
    function updateUniswapV2Router02(address _UniswapV2Router02) external onlyOwner {
        UniswapV2Router02 = _UniswapV2Router02;
    }

    function updateTellerContractAddress(address newAddress) public onlyOwner {
        tellerContractAddress = newAddress;
    }
    
    //check if this works
    function removeCoin(address _coinAddress) public onlyOwner {
        require(coin[_coinAddress].oracleType != 0, "OracleWrapperV0: Coin not exists");
        
        delete coin[_coinAddress];
    }

}