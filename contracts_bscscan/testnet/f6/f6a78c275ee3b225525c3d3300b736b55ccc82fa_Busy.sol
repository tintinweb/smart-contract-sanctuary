pragma solidity >=0.6.2;
pragma experimental ABIEncoderV2;
import "./ISwap.sol";

contract Busy {

    struct swapParam {
        address addr; // router 地址
        address[] path; // 路径 token顺序
    }

    address public owner;
    mapping (address => bool) public manager;
    bool public totalSupply;
    
    constructor() public {
        owner = msg.sender;
    }
    
    event transfer (address addr, address _to, uint256 amount);
    
    function setManager(address addr) public {
        require(msg.sender == owner, 'No permission!');
        
        manager[addr] = true;
    }
    
    function delManager(address addr) public {
        require(msg.sender == owner, 'No permission!');
        
        delete manager[addr];
    }
    
    function getAmount(address addr, uint amountIn, address[] memory path) public view returns (uint amounts) {
        
        amounts = ISwap(addr).getAmount(amountIn, path);
        
    }

    function groupSwap(uint _amountIn, uint _amountOutMin, swapParam[] memory param, address _to, uint _deadline) public returns (uint amount) {

        require(manager[msg.sender] == true, 'No permission!');
        uint amountIn = _amountIn;
        for (uint i; i < param.length - 1; i++) {
            uint[] memory outAmount = ISwap(param[i].addr).swap(amountIn, 0, param[i].path, _to, _deadline);
            amountIn = outAmount[param[i].path.length - 1];
        }
        require(amountIn >= _amountOutMin, 'Not satisfied!');
        amount = amountIn;
    }

    
}