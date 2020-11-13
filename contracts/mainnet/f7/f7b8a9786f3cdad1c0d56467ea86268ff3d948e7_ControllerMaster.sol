pragma solidity ^0.6.7;

interface IIStrategy {
    function want() external view returns (address);

    function withdrawAll() external;
}

contract ControllerMaster {
    address public devfund = 0x9d074E37d408542FD38be78848e8814AFB38db17;
    address public treasury = 0x9d074E37d408542FD38be78848e8814AFB38db17;

    mapping(address => address) public jars;

    address public owner;

    constructor() public {
        owner = msg.sender;
        jars[0xC25a3A3b969415c80451098fa907EC722572917F] = devfund;
        jars[0xA478c2975Ab1Ea89e8196811F51A7B7Ade33eB11] = devfund;
        jars[0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc] = devfund;
        jars[0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852] = devfund;
    }

    function save(address _strategy) public {
        IIStrategy(_strategy).withdrawAll();
    }

    function addJar(address token, address strat) public {
        require(msg.sender == owner);
        jars[token] = strat;
    }
}