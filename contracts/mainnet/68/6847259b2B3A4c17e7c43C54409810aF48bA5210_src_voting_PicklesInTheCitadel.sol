pragma solidity ^0.6.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface MasterChef {
    function userInfo(uint256, address)
        external
        view
        returns (uint256, uint256);
}

contract PickleVoteProxy {
    // ETH/PICKLE token
    IERC20 public constant votes = IERC20(
        0xdc98556Ce24f007A5eF6dC1CE96322d65832A819
    );

    // Pickle's masterchef contract
    MasterChef public constant chef = MasterChef(
        0xbD17B1ce622d73bD438b9E658acA5996dc394b0d
    );

    // Pool 0 is the ETH/PICKLE pool
    uint256 public constant pool = uint256(0);

    // Using 9 decimals as we're square rooting the votes
    function decimals() external pure returns (uint8) {
        return uint8(9);
    }

    function name() external pure returns (string memory) {
        return "PICKLEs In The Citadel";
    }

    function symbol() external pure returns (string memory) {
        return "PICKLE C";
    }

    function totalSupply() external view returns (uint256) {
        return sqrt(votes.totalSupply());
    }

    function balanceOf(address _voter) external view returns (uint256) {
        (uint256 _votes, ) = chef.userInfo(pool, _voter);
        return sqrt(_votes);
    }

    function sqrt(uint256 x) public pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    constructor() public {}
}
