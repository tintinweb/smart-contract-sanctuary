/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

pragma solidity ^0.6.11;

interface SpotterLike {
    function poke(bytes32) external;
}

interface PauseLike {
    function delay() external returns (uint);
    function exec(address, bytes32, bytes memory, uint256) external;
    function plot(address, bytes32, bytes memory, uint256) external;
}

interface ConfigLike {
    function file(bytes32, bytes32, uint) external;
    
    function file(bytes32, uint) external;
}

interface JugLike {
    function drip(bytes32) external returns (uint);
}

contract IlkUpdater {
    function update(address _vat, address _jug) external {
        // 1M
        ConfigLike(_vat).file("BUSD-A", "line", 0x0000000000000000000002ac3a4edbbfb8014e3ba83411e915e8000000000000);
        
    	// 15%, 1000000004431822129783699001
    	JugLike(_jug).drip("BNB-A");
    	ConfigLike(_jug).file("BNB-A", "duty", 1000000004431822129783699001);
    	
    	JugLike(_jug).drip("ETH-A");
    	ConfigLike(_jug).file("ETH-A", "duty", 1000000004431822129783699001);
        
    	JugLike(_jug).drip("BTCB-A");
    	ConfigLike(_jug).file("BTCB-A", "duty", 1000000004431822129783699001);
    	
    	// 20%, 1000000005781378656804591712
    	JugLike(_jug).drip("BUSD-A");
    	ConfigLike(_jug).file("BUSD-A", "duty", 1000000005781378656804591712);
    }
}

contract DssSpellAction {
    bool      public done;
    address   public pause;

    address   public action;
    bytes32   public tag;
    uint256   public eta;
    bytes     public sig;

    constructor(address _pause, address _vat, address _jug) public {
        pause = _pause;
        address ilkUpdater = address(new IlkUpdater());
        sig = abi.encodeWithSignature("update(address,address)", _vat, _jug);
        bytes32 _tag; assembly { _tag := extcodehash(ilkUpdater) }
        action = ilkUpdater;
        tag = _tag;
    }

    function schedule() external {
        require(eta == 0, "spell-already-scheduled");
        eta = now + PauseLike(pause).delay();
        PauseLike(pause).plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        PauseLike(pause).exec(action, tag, sig, eta);
    }
}