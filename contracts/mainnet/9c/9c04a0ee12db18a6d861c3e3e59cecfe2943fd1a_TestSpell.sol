pragma solidity 0.5.12;
// https://github.com/dapphub/ds-pause
contract DSPauseAbstract {
    function setOwner(address) public;
    function setAuthority(address) public;
    function setDelay(uint256) public;
    function plans(bytes32) public view returns (bool);
    function proxy() public view returns (address);
    function delay() public view returns (uint256);
    function plot(address, bytes32, bytes memory, uint256) public;
    function drop(address, bytes32, bytes memory, uint256) public;
    function exec(address, bytes32, bytes memory, uint256) public returns (bytes memory);
}

// https://github.com/monolithos/dss/blob/master/src/jug.sol
contract JugAbstract {
    function wards(address) public view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function ilks(bytes32) public view returns (uint256, uint256);
    function vat() public view returns (address);
    function vow() public view returns (address);
    function base() public view returns (address);
    function init(bytes32) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, uint256) external;
    function file(bytes32, address) external;
    function drip(bytes32) external returns (uint256);
}
contract SpellAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    string constant public description = "2020-08-24 Test Spell";

    address constant public MCD_JUG             = 0xF38d987939084c68a2078Ff6FC8804a994197eBC;
    // decimals & precision
    uint256 constant public MILLION             = 10 ** 6;
    uint256 constant public RAD                 = 10 ** 45;
    function execute() external {
        JugAbstract(MCD_JUG).file("base", 0);
    }
}
contract TestSpell {
    DSPauseAbstract  public pause =
        DSPauseAbstract(0xD4A71B333607549386aDCf528bAd2D096122F31c);
    address          public action;
    bytes32          public tag;
    uint256          public eta;
    bytes            public sig;
    uint256          public expiration;
    bool             public done;
    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }
    function description() public view returns (string memory) {
        return SpellAction(action).description();
    }
    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}