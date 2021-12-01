pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;


// Declare the LBP Swap function prototype 
interface ITest {
   function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    // Structure of Swap 
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    // Struct for Fund Management
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

 
}

// Main contract
contract Interaction {
    
    // Address of the sale contract 
    address Addr;
    uint256 limit; 
    uint256 deadline;
    bool public result; 
    uint256 amount;
    bytes userdata;
    bytes32 pool;
    address _address; 
    address payable recipient;
    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    //address public constant OTHER_CONTRACT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address public constant OTHER_CONTRACT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    ITest BalContract = ITest(OTHER_CONTRACT);

    constructor (address _addr, bytes32 _pool) {
        _address = _addr;
        pool = _pool;
        amount =  15000000; 
        limit = 15000000 / 0.8;  
        deadline = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        userdata = "0x";
        //recipient = payable(0x1dF709474d1Fbe1005cE2a11570A53813618e650);
        recipient = payable(0x58E6aa8773E0fc143a5fF9e9b953d30cDeb545b0);
    }

    // Structure of Swap 
    struct Swp {
        bytes32 poolId;
        uint256 kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    // Struct for Fund Management
    struct funds {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    Swp swap = Swp(pool, 0, 0xdFCeA9088c8A88A76FF74892C1457C17dfeef9C1, _address, amount, userdata);
    funds fnd = funds(msg.sender, false, recipient, false); 
    
    	
    
    function fire() external returns (uint) {
        bytes memory data = abi.encodeWithSignature("swap((bytes32,enum,address,address,uint256,bytes),(address,bool,address,bool),uint256,uint256)", swap,fnd,limit,deadline); 
        address(BalContract).call(data);
    }

}