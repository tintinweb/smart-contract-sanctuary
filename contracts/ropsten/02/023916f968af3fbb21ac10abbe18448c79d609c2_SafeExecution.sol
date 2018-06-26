pragma solidity ^0.4.23;

contract SafeExecution {
    
    address public owner;
    
    modifier noOwner() {
        require(owner == 0, &#39;level already completed&#39;);
        _;
    }
    
    bytes4 internal constant SET = bytes4(keccak256(&#39;Set(uint256)&#39;));
    
    function execute(address _target) public noOwner {
        require(_target.delegatecall(abi.encodeWithSelector(this.execute.selector)) == false, &#39;unsafe execution&#39;);
        
        (bytes4 sel, uint val) = getRet();
        require(sel == SET);
        function () func;
        assembly { func := val }
        func();
    }
    
    function getRet() internal pure returns (bytes4 sel, uint val) {
        assembly {
            if iszero(eq(returndatasize, 0x24)) { revert(0, 0) }
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, 0x24)
            sel := and(mload(ptr), 0xffffffff00000000000000000000000000000000000000000000000000000000)
            val := mload(add(0x04, ptr))
        }
    }
    
    function setOwnerExt() external { if (false) setOwner(); }
    
    function setOwner() private { owner = msg.sender; }
}