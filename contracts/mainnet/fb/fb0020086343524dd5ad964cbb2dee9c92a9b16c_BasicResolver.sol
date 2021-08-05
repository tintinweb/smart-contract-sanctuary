/**
 *Submitted for verification at Etherscan.io on 2020-04-30
*/

pragma solidity ^0.6.0;

// interface OneInchInterace {

// }

interface OneSplitInterface {
    function swap(
        TokenInterface fromToken,
        TokenInterface toToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] calldata distribution, // [Uniswap, Kyber, Bancor, Oasis]
        uint256 disableFlags // 16 - Compound, 32 - Fulcrum, 64 - Chai, 128 - Aave, 256 - SmartToken, 1024 - bDAI
    ) external payable;

    function getExpectedReturn(
        TokenInterface fromToken,
        TokenInterface toToken,
        uint256 amount,
        uint256 parts,
        uint256 disableFlags
    )
    external
    view
    returns(
        uint256 returnAmount,
        uint256[] memory distribution
    );
}


interface TokenInterface {
    function allowance(address, address) external view returns (uint);
    function balanceOf(address) external view returns (uint);
    function approve(address, uint) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
}

// interface MemoryInterface {
//     function getUint(uint _id) external returns (uint _num);
//     function setUint(uint _id, uint _val) external;
// }

// interface EventInterface {
//     function emitEvent(uint _connectorType, uint _connectorID, bytes32 _eventCode, bytes calldata _eventData) external;
// }

contract DSMath {

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    uint constant WAD = 10 ** 18;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

}


contract Helpers is DSMath {
    /**
     * @dev Return ethereum address
     */
    function getAddressETH() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
    }

    // /**
    //  * @dev Return Memory Variable Address
    //  */
    // function getMemoryAddr() internal pure returns (address) {
    //     return 0x8a5419CfC711B2343c17a6ABf4B2bAFaBb06957F; // InstaMemory Address
    // }

    // /**
    //  * @dev Return InstaEvent Address.
    //  */
    // function getEventAddr() internal pure returns (address) {
    //     return 0x2af7ea6Cb911035f3eb1ED895Cb6692C39ecbA97; // InstaEvent Address
    // }

    // /**
    //  * @dev Get Uint value from InstaMemory Contract.
    // */
    // function getUint(uint getId, uint val) internal returns (uint returnVal) {
    //     returnVal = getId == 0 ? val : MemoryInterface(getMemoryAddr()).getUint(getId);
    // }

    // /**
    //  * @dev Set Uint value in InstaMemory Contract.
    // */
    // function setUint(uint setId, uint val) internal {
    //     if (setId != 0) MemoryInterface(getMemoryAddr()).setUint(setId, val);
    // }

    // /**
    //  * @dev Connector Details
    // */
    // function connectorID() public pure returns(uint _type, uint _id) {
    //     (_type, _id) = (1, 0);
    // }
}


contract CompoundHelpers is Helpers {
    // /**
    //  * @dev Return 1 Inch Address
    //  */
    // function getOneInchAddress() internal pure returns (address) {
    //     return 0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B;
    // }

    /**
     * @dev Return 1 Split Address
     */
    function getOneSplitAddress() internal pure returns (address) {
        return 0xC586BeF4a0992C495Cf22e1aeEE4E446CECDee0E;
    }
}


contract BasicResolver is CompoundHelpers {

    function sell(
        address buyAddr,
        address sellAddr,
        uint sellAmt,
        uint unitAmt,
        uint getId
    ) external payable {
        TokenInterface _buyAddr = TokenInterface(buyAddr);
        TokenInterface _sellAddr = TokenInterface(sellAddr);
        OneSplitInterface oneSplitContract = OneSplitInterface(getOneSplitAddress());
        uint ethAmt = getAddressETH() == sellAddr ? sellAmt : 0;
        (uint buyAmt, uint[] memory distribution) =
        oneSplitContract.getExpectedReturn(
                _buyAddr,
                _sellAddr,
                sellAmt,
                unitAmt,
                getId
            );
        oneSplitContract.swap.value(ethAmt)(
            _buyAddr,
            _sellAddr,
            sellAmt,
            buyAmt,
            distribution,
            getId
        );
    }

}