pragma solidity ^0.4.11;

contract Initable {
    function init(address token);
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


// Time-locked wallet for Genesis Vision team tokens
contract GVTTeamAllocator is Initable {
    // Address of team member to allocations mapping
    mapping (address => uint256) allocations;

    ERC20Basic gvt;
    uint unlockedAt;
    uint tokensForAllocation;
    address owner;

    function GVTTeamAllocator() {
        unlockedAt = now + 12 * 30 days;
        owner = msg.sender;
        
        allocations[0x3787C4A087fd3226959841828203D845DF21610c] = 38;
        allocations[0xb205b75E932eC8B5582197052dB81830af372480] = 25;
        allocations[0x8db451a2e2A2F7bE92f186Dc718CF98F49AaB719] = 15;
        allocations[0x3451310558D3487bfBc41C674719a6B09B7C3282] = 7;
        allocations[0x36f3dAB9a9408Be0De81681eB5b50BAE53843Fe7] = 5; 
        allocations[0x3dDc2592B66821eF93FF767cb7fF89c9E9C060C6] = 3; 
        allocations[0xfD3eBadDD54cD61e37812438f60Fb9494CBBe0d4] = 2;
        allocations[0xfE8B87Ae4fe6A565791B0cBD5418092eb2bE9647] = 2;
        allocations[0x04FF8Fac2c0dD1EB5d28B0D7C111514055450dDC] = 1;           
        allocations[0x1cd5B39373F52eEFffb5325cE4d51BCe3d1353f0] = 1;       
        allocations[0xFA9930cbCd53c9779a079bdbE915b11905DfbEDE] = 1;        
              
    }

    function init(address token) {
        require(msg.sender == owner);
        gvt = ERC20Basic(token);
    }

    // Unlock team member&#39;s tokens by transferring them to his address
    function unlock() external {
        require (now >= unlockedAt);

        // Update total number of locked tokens with the first unlock attempt
        if (tokensForAllocation == 0)
            tokensForAllocation = gvt.balanceOf(this);

        var allocation = allocations[msg.sender];
        allocations[msg.sender] = 0;
        var amount = tokensForAllocation * allocation / 100;

        if (!gvt.transfer(msg.sender, amount)) {
            revert();
        }
    }
}