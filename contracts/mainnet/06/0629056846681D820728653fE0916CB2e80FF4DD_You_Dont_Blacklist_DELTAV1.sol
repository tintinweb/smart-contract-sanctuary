/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File contracts/interfaces/IWETH.sol

pragma solidity >=0.6.0 <0.8.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external;
}


// File contracts/v076/You_Dont_Blacklist_DELTA.sol

pragma abicoder v2;

interface IVGT {
    function initialize(string memory) external;
    function generateVolume() external;
    function flashBorrowCaller(uint256, address) external;
    function adjustBalance(address account, uint256 amount, bool isAddition) external;
}

interface IFLASH_LOANER {
    function initiateFlashLoan(address) external;
}

// A factory that creates volume generating tokens
contract You_Dont_Blacklist_DELTAV1 {

    address public immutable MASTER_COPY;
    IFLASH_LOANER public immutable FLASH_LOANDER_DYDX;
    IWETH constant public WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address payable private immutable OWNER;
    Token[] public allTokens;
    address immutable private TRADE_GENERATOR;

    struct Token {
        string ticker;
        address tokenAddress;
    }

    function numTokensGenerated() public view returns (uint256) {
        return allTokens.length;
    }

    constructor(address flasher, address generator, address masterCopy) public {
        OWNER = msg.sender;
        TRADE_GENERATOR = generator;
        MASTER_COPY = masterCopy;
        FLASH_LOANDER_DYDX = IFLASH_LOANER(flasher);
    }



    function createToken(string memory symbol) public {
        address newToken = address(new TokenProxy(MASTER_COPY));

        IVGT(newToken).initialize(symbol);
        // We flash borrow everything in dydx

        FLASH_LOANDER_DYDX.initiateFlashLoan(newToken); 


        allTokens.push(Token({
            ticker : symbol,
            tokenAddress : newToken
        }));

    }



    function destroy() public {
        require(msg.sender == OWNER, "!owner");
        selfdestruct(OWNER);
    }

}





contract TokenProxy {

    // masterCopy always needs to be first declared variable, to ensure that it is at the same location in the contracts to which calls are delegated.
    // To reduce deployment costs this variable is internal and needs to be retrieved via `getStorageAt`
    address internal immutable MASTER_COPY;

    /// @dev Constructor function sets address of master copy contract.
    /// @param _masterCopy Master copy address.
    constructor(address _masterCopy)
        public
    {
        require(_masterCopy != address(0), "Invalid master copy address provided");
        MASTER_COPY = _masterCopy;
    }

    receive () external payable virtual {
        _fallback();
    }

    fallback () external payable virtual {
        _fallback();
    }

    function _fallback() internal virtual {
        _delegate(MASTER_COPY);
    }

    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}