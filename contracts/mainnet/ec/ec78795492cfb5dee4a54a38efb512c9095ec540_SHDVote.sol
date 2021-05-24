/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// File: contracts/SHDVote.sol

pragma solidity ^0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ShadingDAOMining {
    function getUserInfoByPids(uint256[] memory _pids, address _user)
        external
        view
        returns (
            uint256[] memory _amount,
            uint256[] memory _originWeight,
            uint256[] memory _modifiedWeight,
            uint256[] memory _endBlock
        );
}

contract SHDVote {
    
    IERC20 public constant votes = IERC20(0xbECE15ed02A078272a3044827E68D33ef2db8335);
    ShadingDAOMining public constant mining = ShadingDAOMining(0x627Af3B7bB61CB5E96a1F31277eb387DeFe737A1);
    uint public constant pool = uint(0);
    
    function decimals() external pure returns (uint8) {
        return uint8(18);
    }
    
    function name() external pure returns (string memory) {
        return "SHDVote";
    }
    
    function symbol() external pure returns (string memory) {
        return "SHDVOTE";
    }
    
    function totalSupply() external view returns (uint) {
        return votes.totalSupply();
    }
    
    function balanceOf(address _voter) external view returns (uint) {
        uint256[] memory pools = new uint256[](1);
        pools[0] = pool;
        (uint256[] memory _votes,,,) = mining.getUserInfoByPids(pools, _voter);
        return _votes[0];
    }
    
    constructor() public {}
}