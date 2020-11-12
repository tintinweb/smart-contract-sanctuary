pragma solidity ^0.5.17;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface UniswapAnchoredView {
    function price(string calldata) external view returns (uint256);
}

interface OracleSecurityModule {
    function peek() external view returns (bytes32, bool);

    function peep() external view returns (bytes32, bool);

    function bud(address) external view returns (uint256);
}

contract OSMedianizer {
    using SafeMath for uint256;

    mapping(address => bool) public authorized;
    address public governance;

    OracleSecurityModule public constant OSM = OracleSecurityModule(0xf185d0682d50819263941e5f4EacC763CC5C6C42);
    UniswapAnchoredView public constant MEDIANIZER = UniswapAnchoredView(0x9B8Eb8b3d6e2e0Db36F41455185FEF7049a35CaE);
    string public symbol = "BTC";

    constructor() public {
        governance = msg.sender;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setAuthorized(address _authorized) external {
        require(msg.sender == governance, "!governance");
        authorized[_authorized] = true;
    }

    function revokeAuthorized(address _authorized) external {
        require(msg.sender == governance, "!governance");
        authorized[_authorized] = false;
    }

    function read() external view returns (uint256 price, bool osm) {
        if (authorized[msg.sender] && OSM.bud(address(this)) == 1) {
            (bytes32 _val, bool _has) = OSM.peek();
            if (_has) return (uint256(_val), true);
        }
        return ((MEDIANIZER.price(symbol)).mul(1e12), false);
    }

    function foresight() external view returns (uint256 price, bool osm) {
        if (authorized[msg.sender] && OSM.bud(address(this)) == 1) {
            (bytes32 _val, bool _has) = OSM.peep();
            if (_has) return (uint256(_val), true);
        }
        return ((MEDIANIZER.price(symbol)).mul(1e12), false);
    }
}