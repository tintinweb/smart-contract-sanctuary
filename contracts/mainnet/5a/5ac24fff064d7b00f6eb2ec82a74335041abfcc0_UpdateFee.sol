/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

pragma solidity ^0.5.12;



interface RegistryLike {
    function list() external view returns (bytes32[] memory);
}


interface JugLike {
    function drip(bytes32 ilk) external returns (uint rate);
}


contract UpdateFee {

    RegistryLike public registry;
    JugLike public jug;

    address deployer;


    constructor() public {
        deployer = msg.sender;
    }


    function setup(
        address _registry,
        address _jug
    ) public {
        require(deployer == msg.sender, "auth");
        require(_registry != address(0), "registry is null");
        require(_jug != address(0), "jug is null");
        registry = RegistryLike(_registry);
        jug = JugLike(_jug);
    }

    function update() public {
        bytes32[] memory ilks = registry.list();
        for (uint256 i = 0; i < ilks.length; i++) {
            jug.drip(ilks[i]);
        }
    }
}